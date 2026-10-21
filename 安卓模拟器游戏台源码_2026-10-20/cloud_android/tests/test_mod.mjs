import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createDraft,copy,validate,diff,estimate,draw} from '../web/mod/core.mjs';
const seed=JSON.parse(fs.readFileSync(new URL('../web/mod/seed.json',import.meta.url)));
const errors=d=>validate(d,seed).filter(x=>x.level==='error');
test('clone uses distinct IDs without mutating source; nested skill references remapped',()=>{
 const original=JSON.stringify(seed),d=createDraft(seed);assert.equal(errors(d).length,0);assert.equal(JSON.stringify(seed),original);
 assert.equal(d.skills['990001'].levels['1'].property[0].pair_up_id,'990001');assert.deepEqual(d.skills['990002'].base.pair_up_ids,[990002]);
});
test('duplicate character ID and broken skill reference fail validation',()=>{const d=createDraft(seed);d.character.pet_basic_info.pet_id='1001';d.character.pet_active_skill.skill_id='404';assert.ok(errors(d).some(x=>x.path==='pet_id'));assert.ok(errors(d).some(x=>x.path==='skill_id'));});
test('CD mismatch and missing level fail validation',()=>{const d=createDraft(seed);d.skills['990001'].levels['1'].cd=20;delete d.skills['990002'].levels['3'];assert.equal(errors(d).length,2);});
test('unsupported effects are identified and never silently simulated',()=>{const d=createDraft(seed);d.skills['990001'].levels['1'].property[0].affects[0].skill_type_id='999';assert.ok(validate(d,seed).some(x=>x.message.includes('未支持')));assert.throws(()=>estimate(d,'pve',1,452));});
test('known template produces expected arithmetic with explicit cap',()=>{const d=createDraft(seed);assert.equal(estimate(d,'pve',1,452).rawDamage,1356);assert.equal(estimate(d,'pve',1,10000).buffs[0].hypotheticalHeal,500);assert.equal(estimate(d,'pvp',1,100).rawDamage,70);});
test('weighted draws reproducible, count conserved, zero weights never drawn',()=>{const pool=[{id:'1',weight:0},{id:'2',weight:1},{id:'3',weight:3}];const a=draw(pool,10000,42);assert.deepEqual(a,draw(pool,10000,42));assert.equal(a[0].count,0);assert.equal(a.reduce((s,x)=>s+x.count,0),10000);assert.ok(Math.abs(a[1].observed-.25)<.02);assert.throws(()=>draw(pool,100001,42));assert.throws(()=>draw([{weight:0}],10,42));});
test('bad pool weights and duplicate reward IDs are blocked',()=>{const d=createDraft(seed);d.pool=[{id:'1001',weight:-1},{id:'1001',weight:NaN}];assert.ok(errors(d).length>=3);});
test('diff captures additions, removals and changed fields',()=>{assert.deepEqual(diff({a:1,b:2},{a:3,c:4}).map(x=>x.path),['$.a','$.b','$.c']);});
test('import/export JSON round trip preserves complete draft',()=>{const d=createDraft(seed);assert.deepEqual(copy(d),d);assert.equal(errors(copy(d)).length,0);assert.ok(validate(null,seed).some(x=>x.level==='error'));});

test('nested stale character references are detected',()=>{const d=createDraft(seed);d.character.extra={pet_id:'1001'};assert.ok(errors(d).some(x=>x.path==='character.extra.pet_id'));});

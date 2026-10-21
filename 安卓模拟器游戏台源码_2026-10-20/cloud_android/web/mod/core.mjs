export const copy = x => JSON.parse(JSON.stringify(x));
export function remapCharacterId(character,oldId,newId) {
  function walk(value) {
    if(!value||typeof value!=='object')return;
    for(const [key,v] of Object.entries(value)) {
      if(key==='pet_id'&&String(v)===String(oldId))value[key]=typeof v==='number'?Number(newId):String(newId);
      else walk(v);
    }
  }
  walk(character);
}
export function createDraft(seed, id='900001', pve='990001', pvp='990002') {
  const character=copy(seed.character), skills={};
  remapCharacterId(character,'1001',id);
  character.pet_basic_info.pet_id=id; character.pet_basic_info.name='新角色 · 伊凡原型';
  const old=character.pet_active_skill;
  for(const [key,next] of [['skill_id',pve],['pvp_skill_id',pvp]]) {
    const prev=String(old[key]); const skill=copy(seed.skills[prev]);
    function remap(v,k='') {
      if(Array.isArray(v)) return v.map(x=>remap(x,k));
      if(v && typeof v==='object') return Object.fromEntries(Object.entries(v).map(([a,b])=>[a,remap(b,a)]));
      if(['id','skill_id','pair_up_id','pair_up_ids'].includes(k) && String(v)===prev) return typeof v==='number'?Number(next):next;
      return v;
    }
    skills[next]=remap(skill);old[key]=next;
  }
  // Groups are evidence about the original character, not membership for the new one.
  character.pet_groups_by_membership={};
  return {schemaVersion:1,mode:'new',templateId:'1001',character,skills,
    resourceKeys:['Char/Char_1001/Char_1001_Icon'],
    pool:[{id:'1001',label:'伊凡',weight:99},{id,label:'新角色',weight:1}],
    checks:[{name:'角色显示与头像',status:'未测试',notes:''},{name:'获得、上阵与技能',status:'未测试',notes:''},{name:'结算与存档恢复',status:'未测试',notes:''}],notes:''};
}
const numeric=(x,min=0)=> (typeof x==='number'||typeof x==='string'&&x.trim()!=='') && Number.isFinite(Number(x))&&Number(x)>=min;
const object=x=>x && typeof x==='object'&&!Array.isArray(x);
export function validate(d,seed) {
 const issues=[];const add=(level,path,message)=>issues.push({level,path,message});
 if(!object(d)||d.schemaVersion!==1||!object(d.character)||!object(d.skills)) return [{level:'error',path:'$',message:'需要 schemaVersion=1、character 和 skills 对象'}];
 const b=d.character.pet_basic_info,link=d.character.pet_active_skill;
 if(!object(b)||!object(link)) return [{level:'error',path:'character',message:'缺少 pet_basic_info 或 pet_active_skill'}];
 if(!['new','override'].includes(d.mode))add('error','mode','应为 new 或 override');
 const id=String(b.pet_id);
 if(!/^[1-9]\d{0,8}$/.test(id))add('error','pet_id','角色 ID 必须是 1–9 位正整数');
 if(d.mode==='new'&&seed.existingCharacterIds.includes(id))add('error','pet_id','新增角色 ID 与原配置冲突');
 if(d.mode==='override'&&!seed.existingCharacterIds.includes(id))add('error','pet_id','覆盖模式的角色 ID 不存在');
 if(typeof b.name!=='string'||!b.name.trim())add('error','name','角色名称不能为空');
 function checkPetRefs(v,path){if(!v||typeof v!=='object')return;for(const [k,x]of Object.entries(v)){if(k==='pet_id'&&String(x)!==id)add('error',path+'.'+k,'角色引用未同步：'+x);else if(k!=='pet_groups_by_membership')checkPetRefs(x,path+'.'+k);}}
 checkPetRefs(d.character,'character');
 for(const k of ['base_hp','base_atk','base_rhp','max_hp','max_atk','max_rhp','max_lv'])if(!numeric(b[k],k==='max_lv'?1:0))add('error',k,'需要有效非负数值（等级至少 1）');
 for(const k of ['hp','atk','rhp'])if(Number(b['max_'+k])<Number(b['base_'+k]))add('error',k,'最大属性小于基础属性');
 if(Number(b.max_lv)>Number(d.character.global_limits?.pet_level_limit))add('warning','max_lv','超过提取的全局等级上限；运行时优先级未确认');
 if(String(link.skill_id)===String(link.pvp_skill_id))add('warning','pet_active_skill','PVE/PVP 共用技能，请确认意图');
 for(const k of ['skill_id','pvp_skill_id'])if(!d.skills[link[k]])add('error',k,'绑定技能不存在');
 for(const [sid,s] of Object.entries(d.skills)){
  const path='skills.'+sid;
  if(!/^[1-9]\d{0,8}$/.test(sid))add('error',path,'技能 ID 格式错误');
  if(d.mode==='new'&&seed.existingSkillIds.includes(sid))add('error',path,'技能 ID 与原配置冲突');
  if(!object(s?.base)||!object(s?.levels)){add('error',path,'缺少 base 或 levels');continue;}
  if(String(s.base.id)!==sid||String(s.levels.skill_id)!==sid)add('error',path,'技能表键与内部 ID 不一致');
  const n=Number(s.base.level_limit);
  if(!Number.isInteger(n)||n<1||n>100){add('error',path,'技能等级上限应为 1–100');continue;}
  for(let i=1;i<=n;i++){
   const l=s.levels[i],p=path+'.levels.'+i;
   if(!object(l)){add('error',p,'缺少等级记录');continue;}
   if(String(l.id)!==sid)add('error',p,'等级记录 ID 不一致');
   if(!numeric(l.cd)||!Number.isInteger(Number(l.cd)))add('error',p+'.cd','CD 应为非负整数');
   if(Number(s.base.cd?.[i-1])!==Number(l.cd))add('error',p+'.cd','基础表 CD 与等级表不一致');
   if(!Array.isArray(l.property)){add('error',p,'缺少 property 效果列表');continue;}
   for(const prop of l.property){
    if(!Array.isArray(prop?.affects)){add('error',p,'缺少 affects 数组');continue;}
    for(const a of prop.affects){
     if(!object(a)){add('error',p,'效果必须为对象');continue;}
     if(!['1','73'].includes(String(a.skill_type_id)))add('warning',p,'未支持的效果 '+a.skill_type_id+'，不能在数值试算中执行');
     if(!Array.isArray(a.affect_values)||a.affect_values.some(v=>!numeric(v)))add('error',p,'效果参数应为非负数值数组');
     else if(a.affect_values.length<(String(a.skill_type_id)==='73'?3:1))add('error',p,'效果参数数量不足');
    }
   }
  }
 }
 if(!Array.isArray(d.resourceKeys)||!d.resourceKeys.length)add('error','resourceKeys','至少提供一个资源地址');
 else for(const key of d.resourceKeys)if(typeof key!=='string'||!Object.hasOwn(seed.assets,key)&&!Object.hasOwn(seed.modResources||{},key))add('warning','resourceKeys','未在角色 1001 的资源索引中找到：'+String(key));
 if(!Array.isArray(d.pool)||!d.pool.length)add('error','pool','测试卡池不能为空');
 else {const seen=new Set();let total=0;for(const r of d.pool){if(!object(r)){add('error','pool','奖励行必须为对象');continue;}const rid=String(r.id);if(seen.has(rid))add('error','pool','奖励 ID 重复：'+rid);seen.add(rid);if(rid!==id&&!seed.existingCharacterIds.includes(rid))add('error','pool','未知角色：'+rid);if(!numeric(r.weight))add('error','pool','权重必须非负且有限');else total+=Number(r.weight);}if(!(total>0)||!Number.isFinite(total))add('error','pool','权重总和必须为有限正数');}
 if(!Array.isArray(d.checks)||d.checks.some(x=>!object(x)||typeof x.name!=='string'||!['未测试','通过','失败'].includes(x.status)||typeof x.notes!=='string'))add('error','checks','检查项需要 name、status（未测试/通过/失败）、notes');
 add('warning','$','仅验证已提取的配置关系；不验证二进制 schema、Unity 资源注册或真实战斗/抽卡逻辑');
 return issues;
}
export function diff(a,b,path='$',out=[]){
 if(JSON.stringify(a)===JSON.stringify(b))return out;
 if(object(a)&&object(b)){for(const k of new Set([...Object.keys(a),...Object.keys(b)]))diff(a[k],b[k],path+'.'+k,out);}
 else out.push({path,before:a===undefined?null:a,after:b===undefined?null:b});return out;
}
export function draw(pool,count,seed){
 if(!Number.isInteger(count)||count<1||count>100000)throw Error('抽取次数需为 1–100000');
 if(!Number.isInteger(seed)||seed<0||seed>4294967295)throw Error('种子需为 uint32 整数');
 if(!Array.isArray(pool)||!pool.length||pool.some(r=>!numeric(r.weight)))throw Error('无效卡池');
 const total=pool.reduce((s,r)=>s+Number(r.weight),0);if(!(total>0)||!Number.isFinite(total))throw Error('权重总和无效');
 let state=seed>>>0;const hits=pool.map(()=>0);
 for(let i=0;i<count;i++){state=(Math.imul(1664525,state)+1013904223)>>>0;let v=state/4294967296*total;for(let j=0;j<pool.length;j++){v-=Number(pool[j].weight);if(v<0){hits[j]++;break;}}}
 return pool.map((r,i)=>({id:r.id,name:r.label,weight:Number(r.weight),expected:Number(r.weight)/total,count:hits[i],observed:hits[i]/count}));
}
export function estimate(d,mode,level,attack){
 if(!numeric(attack)||Number(attack)>1e12)throw Error('攻击输入需为 0–10¹²');
 const id=d.character.pet_active_skill[mode==='pvp'?'pvp_skill_id':'skill_id'];const l=d.skills[id]?.levels[level];if(!l)throw Error('缺少该等级技能');
 const effects=l.property.flatMap(p=>p.affects);
 if(effects.some(a=>!['1','73'].includes(String(a.skill_type_id))))throw Error('包含未知效果，无法试算');
 const damage=effects.filter(a=>String(a.skill_type_id)==='1');
 if(damage.length!==1)throw Error('仅支持一个 type=1 伤害效果的模板');
 const raw=Number(attack)*Number(damage[0].affect_values[0]);if(!Number.isFinite(raw))throw Error('无效伤害参数');
 return {skillId:id,cd:l.cd,rawDamage:raw,buffs:effects.filter(a=>String(a.skill_type_id)==='73').map(a=>({percent:Number(a.affect_values[0]),cap:Number(a.affect_values[1]),turns:Number(a.affect_values[2]),hypotheticalHeal:Math.min(raw*Number(a.affect_values[0])/100,Number(a.affect_values[1]))}))};
}

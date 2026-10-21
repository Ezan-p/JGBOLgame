import asyncio,json
from pathlib import Path
from playwright.async_api import async_playwright
R=Path(__file__).resolve().parents[1]
async def main():
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless=True)
  page=await browser.new_page(viewport={'width':1440,'height':1050});errors=[];failed=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('response',lambda r:failed.append((r.status,r.url)) if r.status>=400 else None)
  page.on('dialog',lambda d:d.accept())
  await page.goto('http://127.0.0.1:8765/mod/?preset=gojo')
  await page.locator('#gojoStatus').filter(has_text='37 条').wait_for(timeout=30000)
  assert await page.locator('#petid').input_value()=='900002'
  assert '0 个错误' in await page.locator('#summary').inner_text()
  assert await page.locator('#gojoVoice option').count()==37
  await page.locator('#gojoPreview').screenshot(path=str(R/'.runtime/gojo-idle.png'))
  await page.locator('[data-gojo-action="skill"]').click();await page.wait_for_timeout(1250)
  assert await page.locator('#gojoCanvas').get_attribute('data-animation')=='skill'
  await page.locator('#gojoPreview').screenshot(path=str(R/'.runtime/gojo-skill.png'))
  for action in ['attack','hurt','victory','idle']:
   await page.locator(f'[data-gojo-action="{action}"]').click()
   assert await page.locator('#gojoCanvas').get_attribute('data-animation')==action
  await page.locator('#gojoPlay').click();await page.wait_for_timeout(500)
  audio=await page.locator('#gojoAudio').evaluate('(e)=>({time:e.currentTime,duration:e.duration,paused:e.paused,error:e.error?.code})')
  assert audio['time']>0 and not audio['error'],audio
  await page.locator('#gojoStop').click()
  assert await page.locator('#gojoAudio').evaluate('(e)=>e.paused')
  await page.locator('#gojoStory').click();assert '1 / 13' in await page.locator('#gojoProgress').inner_text()
  await page.locator('#gojoNext').click();assert '五条悟' in await page.locator('#gojoSpeaker').inner_text()
  await page.locator('#gojoPreview').screenshot(path=str(R/'.runtime/gojo-story.png'))
  await page.locator('#gojoPrev').click();assert '1 / 13' in await page.locator('#gojoProgress').inner_text()
  await page.set_viewport_size({'width':390,'height':844})
  assert await page.evaluate('document.documentElement.scrollWidth<=innerWidth')
  await page.locator('#gojoPreview').screenshot(path=str(R/'.runtime/gojo-mobile.png'))
  await page.locator('#gojoExit').click()
  assert await page.locator('#attack').input_value()=='480'
  await page.locator('#estimate').click()
  assert json.loads(await page.locator('#skillResult').inner_text())['result']['rawDamage']==1536
  await page.locator('#fresh').click();assert await page.locator('#gojoPreview').is_hidden()
  await page.locator('#loadGojo').click();await page.locator('#gojoPreview').wait_for(state='visible')
  async with page.expect_download() as info:await page.locator('#export').click()
  dl=await info.value;data=json.loads(Path(await dl.path()).read_text());assert data['presentation']['packId']=='gojo-v0.2'
  assert not errors,errors
  assert not failed,failed
  out={'page_errors':errors,'failed_requests':failed,'audio':audio,'checks':['preset load','four images','five-state canvas','37 voice options','audio progresses/stops','story next/previous/exit','mobile overflow','skill estimate','template switching','preset button','export media reference']}
  (R/'.runtime/gojo-browser-check.json').write_text(json.dumps(out,ensure_ascii=False,indent=2));print(json.dumps(out,ensure_ascii=False));await browser.close()
asyncio.run(main())

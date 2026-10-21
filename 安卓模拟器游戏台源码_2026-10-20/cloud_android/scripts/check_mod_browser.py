"""Browser QA of the independent MOD sandbox; does not connect to Android controls."""
import asyncio, json
from pathlib import Path
from playwright.async_api import async_playwright
R=Path(__file__).resolve().parents[1]
async def main():
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless=True)
  page=await browser.new_page(viewport={'width':1440,'height':1000});errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('dialog',lambda d:d.accept())
  await page.goto('http://127.0.0.1:8765/mod/')
  await page.get_by_role('status').filter(has_text='已载入').wait_for()
  assert '0 个错误' in await page.locator('#summary').inner_text()
  await page.locator('#name').fill('QA 自定义角色')
  await page.locator('#validate').click()
  await page.locator('#save').click()
  await page.reload()
  await page.get_by_role('status').filter(has_text='已载入').wait_for()
  await page.locator('#restore').click()
  assert await page.locator('#name').input_value()=='QA 自定义角色'
  await page.locator('#estimate').click()
  assert '1356' in await page.locator('#skillResult').inner_text()
  await page.locator('#draw').click()
  first=await page.locator('#drawResult').inner_text()
  await page.locator('#draw').click()
  assert first==await page.locator('#drawResult').inner_text()
  async with page.expect_download() as info:await page.locator('#export').click()
  dl=await info.value;draft=json.loads(Path(await dl.path()).read_text());assert draft['character']['pet_basic_info']['name']=='QA 自定义角色'
  await page.locator('#import').set_input_files({'name':'roundtrip.json','mimeType':'application/json','buffer':json.dumps(draft).encode()})
  await page.get_by_role('status').filter(has_text='已导入').wait_for()
  await page.locator('#petid').fill('1001');await page.locator('#validate').click()
  assert '新增角色 ID 与原配置冲突' in await page.locator('#issues').inner_text()
  await page.locator('#petid').fill('900001');await page.locator('#validate').click()
  await page.locator('#json').fill('{bad');await page.locator('#apply').click()
  assert '操作未完成' in await page.locator('#notice').inner_text()
  assert await page.locator('#json').input_value()=='{bad'
  await page.locator('#json').fill(json.dumps(draft));await page.locator('#apply').click()
  await page.locator('#estimate').click();await page.locator('#draw').click()
  await page.locator('#addCheck').click()
  assert await page.locator('#checks .check').count()==4
  async with page.expect_download() as info:await page.locator('#report').click()
  report=await info.value;assert '# MOD 测试报告' in Path(await report.path()).read_text()
  await page.screenshot(path=str(R/'.runtime/mod-browser.png'),full_page=True)
  await page.set_viewport_size({'width':390,'height':844})
  assert await page.evaluate('document.documentElement.scrollWidth <= window.innerWidth')
  await page.screenshot(path=str(R/'.runtime/mod-mobile.png'),full_page=True)
  assert not errors,errors
  result={'page_errors':errors,'checks':['template','edit','save/restore','skill estimate','repeatable draw','export/import','collision','invalid JSON preservation','checklist','report download','mobile layout'],'url':'http://127.0.0.1:8765/mod/'}
  (R/'.runtime/mod-browser-check.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps(result,ensure_ascii=False));await browser.close()
asyncio.run(main())

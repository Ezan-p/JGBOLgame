"""Read-only browser smoke check. Never launches or logs into the game."""
import asyncio
import json
import re
import sys
from pathlib import Path
from playwright.async_api import async_playwright, expect

R = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(R))
from game_config import load_config

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(executable_path='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless=True)
        try:
            page = await browser.new_page(viewport={'width': 1440, 'height': 1050})
            errors = []
            page.on('pageerror', lambda e: errors.append(str(e)))
            await page.goto(f"http://127.0.0.1:{load_config()['web_port']}")
            await expect(page.locator('#compatibility')).not_to_have_text(re.compile(r"^正在检查"), timeout=15000)
            initial = await page.evaluate("fetch('/api/status').then(r=>r.json())")
            if initial.get('control_busy'):
                print('Skipped: user already controls the screen')
                return
            if initial.get('emulator'):
                await page.click('#connect')
                await page.locator('#empty').wait_for(state='hidden', timeout=45000)
                await page.wait_for_timeout(1500)
            await page.screenshot(path=str(R / '.runtime/browser-check.png'), full_page=True)
            status = await page.evaluate("fetch('/api/status').then(r=>r.json())")
            out = {'page_errors': errors, 'status': status,
                   'title': await page.title(), 'fps': await page.locator('#fps').inner_text(),
                   'compatibility': await page.locator('#compatibility').inner_text(),
                   'launch_enabled': await page.locator('#launch').is_enabled()}
            await page.set_viewport_size({'width': 390, 'height': 844})
            await page.screenshot(path=str(R / '.runtime/browser-mobile.png'), full_page=True)
            out['mobile_overflow'] = await page.evaluate('document.documentElement.scrollWidth > innerWidth')
            (R / '.runtime/browser-check.json').write_text(json.dumps(out, ensure_ascii=False, indent=2))
            print(json.dumps(out, ensure_ascii=False))
            if errors or out['mobile_overflow']:
                raise RuntimeError('浏览器检查失败')
        finally:
            await browser.close()

asyncio.run(main())

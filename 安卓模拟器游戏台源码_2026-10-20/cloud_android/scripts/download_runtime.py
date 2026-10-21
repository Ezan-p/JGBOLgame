"""Download the exact official archives used in the verified Mac deployment."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1];RT=R/'.runtime';RT.mkdir(exist_ok=True)
URLS={
'repository.xml':'https://dl.google.com/android/repository/repository2-3.xml',
'images.xml':'https://dl.google.com/android/repository/sys-img/google_apis/sys-img2-3.xml',
'emulator.zip':'https://dl.google.com/android/repository/emulator-darwin_aarch64-16428233.zip',
'platform-tools.zip':'https://dl.google.com/android/repository/platform-tools_r37.0.1-darwin.zip',
'build-tools.zip':'https://dl.google.com/android/repository/build-tools_r35_macosx.zip',
'image.zip':'https://dl.google.com/android/repository/sys-img/google_apis/arm64-v8a-30_r16.zip',
'jdk.tar.gz':'https://api.adoptium.net/v3/binary/latest/17/ga/mac/aarch64/jdk/hotspot/normal/eclipse'}
SIZES={'emulator.zip':416112708,'platform-tools.zip':16110554,'build-tools.zip':76857898,'image.zip':1244324730}
if __name__=='__main__':
 for name,url in URLS.items():
  path=RT/name
  if path.exists() and (name in SIZES and path.stat().st_size==SIZES[name]):print('Already downloaded:',name);continue
  # Indexes and moving JDK release URL are not safely resumable across versions.
  cmd=['curl','-fL','--retry','5','--retry-all-errors','--connect-timeout','20','--speed-time','45','--speed-limit','1024']
  if name in SIZES:cmd+=['-C','-']
  subprocess.run(cmd+[url,'-o',str(path)],check=True)

"""Install verified Android archives already downloaded into .runtime."""
from pathlib import Path
import hashlib,json,os,shutil,stat,tarfile,zipfile,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1];RT=ROOT/'.runtime';SDK=RT/'sdk'
PACKAGES=[('platform-tools.zip','repository.xml','platform-tools',SDK),('build-tools.zip','repository.xml','build-tools;35.0.0',SDK/'build-tools'/'35.0.0'),('emulator.zip','repository.xml','emulator',SDK),('image.zip','images.xml','system-images;android-30;google_apis;arm64-v8a',SDK/'system-images'/'android-30'/'google_apis')]
def extract(zpath,dest,strip=False):
 dest.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(zpath) as z:
  for info in z.infolist():
   parts=Path(info.filename).parts
   if strip:parts=parts[1:]
   if not parts:continue
   target=dest.joinpath(*parts)
   if not target.resolve().is_relative_to(dest.resolve()):raise ValueError('Unsafe archive path')
   if info.is_dir():target.mkdir(parents=True,exist_ok=True);continue
   target.parent.mkdir(parents=True,exist_ok=True)
   mode=(info.external_attr>>16)&0xffff
   if stat.S_ISLNK(mode):
    link=z.read(info).decode();resolved=(target.parent/link).resolve()
    if not resolved.is_relative_to(dest.resolve()):raise ValueError('Unsafe symlink')
    if not target.exists():target.symlink_to(link)
   else:
    with z.open(info) as src,target.open('wb') as dst:shutil.copyfileobj(src,dst,1024*1024)
    if mode:target.chmod(mode&0o777)
if __name__=='__main__':
 receipts=[]
 for archive,index,package,dest in PACKAGES:
  p=RT/archive;digest=hashlib.sha1(p.read_bytes()).hexdigest();match=None
  for pkg in ET.parse(RT/index).getroot().findall('remotePackage'):
   if pkg.get('path')!=package:continue
   for a in pkg.findall('archives/archive'):
    if a.findtext('complete/checksum')==digest:match=a
  if match is None:raise ValueError('Official SHA-1 mismatch: '+archive)
  print('Verified and extracting',archive,flush=True);extract(p,dest,archive=='build-tools.zip');receipts.append(dict(archive=archive,sha1=digest,url=match.findtext('complete/url')))
 jdest=RT/'java';jdest.mkdir(exist_ok=True)
 with tarfile.open(RT/'jdk.tar.gz') as t:
  for member in t.getmembers():
   if not (jdest/member.name).resolve().is_relative_to(jdest.resolve()):raise ValueError('Unsafe tar path')
  t.extractall(jdest)
 (RT/'downloads.json').write_text(json.dumps(receipts,indent=2))
 # Use the exact emulator's shipped protocol when available.
 proto=SDK/'emulator/lib/emulator_controller.proto'
 if proto.exists():shutil.copy2(proto,ROOT/'proto/emulator_controller.proto')
 print('Runtime installed',SDK)

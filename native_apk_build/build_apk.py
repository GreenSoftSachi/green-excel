import os
import shutil
import zipfile

print("Starting Green Excel v1 packaging...")
base_apk = "native_apk_build/base.apk"
work_dir = "extracted_apk"
output_unsigned = "unsigned.apk"

if os.path.exists(work_dir):
    shutil.rmtree(work_dir)
os.makedirs(work_dir, exist_ok=True)

# 1. Extract base APK
with zipfile.ZipFile(base_apk, 'r') as zip_ref:
    zip_ref.extractall(work_dir)

# 2. Remove old signatures
meta_inf = os.path.join(work_dir, "META-INF")
if os.path.exists(meta_inf):
    shutil.rmtree(meta_inf)

# 3. Copy replacements
rep_dir = "native_apk_build/replacements"
for root, dirs, files in os.walk(rep_dir):
    for f in files:
        src = os.path.join(root, f)
        rel = os.path.relpath(src, rep_dir)
        dst = os.path.join(work_dir, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
        print(f"Replaced: {rel}")

# 4. Re-zip cleanly
with zipfile.ZipFile(output_unsigned, 'w') as zip_out:
    for root, dirs, files in os.walk(work_dir):
        for f in sorted(files):
            path = os.path.join(root, f)
            arcname = os.path.relpath(path, work_dir).replace('\\', '/')
            compress = zipfile.ZIP_STORED if arcname in ["resources.arsc", "AndroidManifest.xml"] else zipfile.ZIP_DEFLATED
            zip_out.write(path, arcname, compress_type=compress)

print(f"Created {output_unsigned} successfully (Size: {os.path.getsize(output_unsigned)} bytes)")

from base64 import b64encode
import sys
from nacl import encoding, public

public_key = sys.argv[1]
secret_value = sys.argv[2]

public_key = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder())
sealed_box = public.SealedBox(public_key)
encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
print(b64encode(encrypted).decode("utf-8"))

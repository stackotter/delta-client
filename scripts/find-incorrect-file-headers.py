import os

for dire in os.walk("../"):
  for fileName in dire[2]:
    if fileName.endswith(".swift"):
      with open(dire[0] + "/" + fileName, "r") as f:
        headerName = f.readlines()[1][4:].strip()
        if headerName != fileName:
          print(fileName)
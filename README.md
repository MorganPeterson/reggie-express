# Reggie Express

## Requirements

### Install LuaJIT
```sh
mkdir -p reggie-express/include
mkdir -p reggie-express/libs
git clone https://luajit.org/git/luajit.git
cd luajit
make
make install
cp src/*\.h ../reggie-express/include
cp src/*\.a ../reggie-express/libs
```

### Install antifennel
```sh
git clone https://git.sr.ht/~technomancy/antifennel
cd antifennel
make
cp antifennel ../reggie-expressa
```

### Install luastatic
```sh
git clone https://github.com/ers35/luastatic
cp luastatic/luastatic.lua reggie-express/luastatic.lua
```

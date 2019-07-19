# androidSigner
**转载请标注原创地址：[https://blog.csdn.net/lsyz0021/article/details/96499543](https://blog.csdn.net/lsyz0021/article/details/96499543)**

一提到给apk签名，大家或许想这还不简单，打开终端配置好“apksigner”命令一行不就搞定了，但是如果让你给100个apk签名，这样的方式好简单吗？
因为最近有经常要给apk签名的需要，并且有时候可能要同时给十几个apk签名，所以就想到了写个批量v2签名的shell脚本，写完之后使用感觉起来感觉也特别方便。想到或许其他人也可能会有这种需求，于是将他开源出来供大家使用。废话不多说先介绍功能！

## 1、设置配置文件
`signerConfig.ini`配置文件可以不使用，默认在当前目录下搜索，这时就需要手动输入所有的内容，并且不支持指定搜索目录和输出目录。
这里需要注意：由于`apksigner`命令是在25.0.0版本才出现的，所以`buildTools`配置的**build-tools**版本至少要是25.0.0。

```shell
#签名文件的位置
storeFile=./appkey.jks
#签名文件的密码
storePassword=123456
#key的别名
keyAlias=appkey
#key的密码
keyPassword=12345678
#sdk中build-tools的路径，apksigner命令25.0.0版本才出现
buildTools=/Users/wuge/sdk/build-tools/29.0.0/
#是否自动搜索指定目录，true:自动搜索，false:手动输入，no:需要选择获取方式
auto=no
#指定搜索目录，"."代表当前目录，不设置此值默认为当前目录
searchPath=.
#指定输出目录，不设置默认为当前目录下的out目录
outPath=./out
```
## 2、执行脚本，选择“y”
配置好上面的内容之后，就可以执行`signer.sh`脚本了。配置文件默认`auto=no`，所以需要手动选择输入方式，下面是输入的`y`，开始在指定目录(`searchPath=.`表示当前目录)下开始自动搜索所有的apk，并且进行签名。
**注意**：如果`auto=true`，相当于输入了`y`，自动就进行搜索指定目录(`searchPath=.`)下的apk
![在这里插入图片描述](https://img-blog.csdnimg.cn/20190719205719878.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2xzeXowMDIx,size_16,color_FFFFFF,t_70)
## 3、生成获取签名apk
执行完`signer.sh`脚本，在指定的输出目录(`outPath=./out`)下生成了签名后的apk，每个签名成功的apk名字前面都会增加"signer-"前缀。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20190719205757300.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2xzeXowMDIx,size_16,color_FFFFFF,t_70)
## 4、执行脚本，选择“n”
这里我们输入`n`，就需要我们手动指定apk的路径了
**注意**：如果`auto=false`，相当于输入了`n`
![在这里插入图片描述](https://img-blog.csdnimg.cn/20190719205807907.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2xzeXowMDIx,size_16,color_FFFFFF,t_70)
[GitHub地址 https://github.com/lsyz0021/androidSigner.git](https://github.com/lsyz0021/androidSigner.git)










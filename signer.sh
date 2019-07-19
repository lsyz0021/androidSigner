configPath=signerConfig.ini # 配置文件的名称

androidCommandPath="" # Android sdk 
findPath="." # 要搜索的目录，默认为当前目录
storeFile="" # 签名文件的路径
storePassword="" # 签名文件的密码
keyAlias="" # key的别名
keyPassword="" # key的密码
auto="false" # 是否自动搜索
configSearchPath="" # 指定搜索的目录，不指定默认问当前目录
configOutPath="" # 指定签名完的apk输出目录，不指定默认为当前目录下的out目录

tatalTimes=0 # 总的签名次数
errorTimes=0 # 失败的签名次数

findApkLastResult="" # 获取查找结果的最后一个apk
findApkArray=() #查找到的所有apk的数组

# 获取配置文件的内容
function findConfigFile()
{
    if [ -f "$configPath" ]; then
        storeFile=`cat $configPath | grep storeFile | awk -F'=' '{ print $2 }' | sed s/[[:space:]]//g`
        storePassword=`cat $configPath | grep storePassword | awk -F'=' '{ print $2 }' | sed s/[[:space:]]//g`
        keyAlias=`cat $configPath | grep keyAlias | awk -F'=' '{ print $2 }' | sed s/[[:space:]]//g`
        keyPassword=`cat $configPath | grep keyPassword | awk -F'=' '{ print $2 }' | sed s/[[:space:]]//g`
        androidCommandPath=`cat $configPath | grep buildTools | awk -F'=' '{ print $2 }' | sed s/[[:space:]]//g`
        auto=`cat $configPath | grep auto | awk -F'=' '{ print $2 }' | sed s/[[:space:]]//g`
        configSearchPath=`cat $configPath | grep searchPath | awk -F'=' '{ print $2 }' | sed s/[[:space:]]//g`
        configOutPath=`cat $configPath | grep outPath | awk -F'=' '{ print $2 }' | sed s/[[:space:]]//g`
    else
        echo -e "\n当前目录下找不到配置文件${configPath},需要手动输入账号和密码，\n强烈建议在当前目录下创建${configPath}配置文件\n"

        read -e -p "第1步(共5部)请输入签名文件地址:" storeFile
        read -p "第2步(共5部)请输入签名密码:" -s storePassword    
        echo ""
        read -p "第3部(共5部)请输入key的别名:" keyAlias
        read -p "第4部(共5部)请输入key的密码:" -s keyPassword
        echo ""
        read -e -p "第5步(共5部)请输入build-tools路径:" androidCommandPath

    fi
}

# 根据指定的目录搜索apk
function findApk()
{
    searchDir=$1
    searchMatchWords=$2
    findApkArray=($(find $searchDir -name $searchMatchWords))
    length=${#findApkArray[*]}
    if [ $length -gt 0 ]; then # 数组元素是否 >= 0
        findApkLastResult=${findApkArray[$length-1]}
     else
        findApkLastResult=""
    fi
}

# V2签名apk
function signAndroidApk()
{
    sourceApk=$1
    outputPath=$2
    if [ ! -f "$sourceApk" ];then
       echo "注意啦！第${tatalTimes}个输入的apk不存在${sourceApk}"
       let errorTimes++
    else
        apkPath=${sourceApk%/*}
        apkName=${sourceApk##*/}

        if [[ "$sourceApk" =~ "signer" ]];then
            echo "注意啦！第${tatalTimes}个Apk已签名,不需要再签名了:$sourceApk"
            let errorTimes++
        else
            # 创建输出的目录
            if [[ -z "$outputPath" ]]; then  # outputPath的值为空
                outputPath=${apkPath}/out
                if [ ! -d "$outputPath" ]; then
                    mkdir -p $outputPath
                    echo 没有指定输出路径,则输出到apk所在目录的out目录:$outputPath
                fi 
            elif [[ ! -d "$outputPath" ]]; then # outputPath目录不存在
                echo 由于${outputPath}路径不存在,则创建该路径。
                mkdir -p $outputPath

                # 创建目录失败
                if [[ ! -d "$outputPath" ]]; then
                    echo 创建${outputPath}目录失败，则输出到apk所在目录的out目录
                    outputPath=${apkPath}/out
                    if [ ! -d "$outputPath" ]; then
                        mkdir -p $outputPath
                    fi
                fi
            fi

            # 检查命令行目录是否存在
            if [[ ! -d "${androidCommandPath}" ]]; then
                echo -e "\n错误！配置的build-tools路径找不到，请检查${configPath}文件中buildTools的设置\n"
                exit 0
            fi
            # 检查zipalign命令是否存在
            zipalign=$androidCommandPath/zipalign
            if [[ ! -f "$zipalign" ]]; then
                echo -e "\n错误！${zipalign} 命令找不到\n"
                exit 0
            fi
            # 检查apksigner命令是否存在
            apksigner=$androidCommandPath/apksigner
            if [[ ! -f "$apksigner" ]]; then
                echo -e "\n错误！${apksigner} 命令找不到，apksigner命令在build-tools 25.0.0才出现\n"
                exit 0
            fi

            zipalignApk="$outputPath/zipalign-$apkName"
            signerApk="$outputPath/signer-$apkName" 

            # 开始4K对齐
            $zipalign -f 4 $sourceApk $zipalignApk
            
            if [[ ! -f "$zipalignApk"  || ! -s "${zipalignApk}" ]];then # 对齐完的apk不是一个文件，或者大小为0kb
                echo "注意啦！第${tatalTimes}个apk 4K对齐失败${zipalignApk}"
                let errorTimes++
                rm -f $zipalignApk
            else
                # 4K对齐成功，开始V2签名
                $apksigner sign --ks $storeFile --ks-pass pass:$storePassword --ks-key-alias $keyAlias --key-pass pass:$keyPassword --out $signerApk $zipalignApk
                # 签名完，删除对齐过程中生成的apk
                rm -f $zipalignApk
                if [  -f "$zipalignApk" ];then
                    echo -e "\n注意！对齐生成的apk删除失败，请手动删除:${zipalignApk}\n"
                fi

                if [ ! -f "$signerApk" ]; then
                    echo -e "\n注意啦！第${tatalTimes}个apk签名失败，没有生成签名的apk\n\n"
                   let errorTimes++
                elif [ ! -s "$signerApk" ];then # 生成的apk大小为0kb
                    echo -e "\n注意啦！第${tatalTimes}个apk签名失败，因为生成签名的apk大小为0KB\n\n"
                    let errorTimes++
                    rm -f $signerApk
                else
                    echo V2签名成功:$signerApk                    
                fi
            fi

        fi
    fi
}

# 根据配置内容选择要获取apk
function getApk()
{
    # 如果配置的目录不为空，并且该目录存在
    if [[ -n "$configSearchPath" && -d "$configSearchPath" ]]; then
        findPath=$configSearchPath
    else
        echo -e "\n由于searchPath=${configSearchPath}目录不存在或者没有配置searchPath的值，则默认在当前目录搜索apk"
        findPath="."
    fi

    if [[ "$auto" == "true" ]]; then
        # 1、自动搜索apk
        echo -e "\n${configPath}中设置auto=true，开始自动搜索${findPath}目录"
        findApk $findPath "*.apk"
    elif [[ "$auto" == "false" ]]; then
         # 2、手动指定apk路径
        echo -e "\n${configPath}中设置auto=false，需要手动输入apk路径"
        echo -e "如果想自动搜索目录下的apk，请在${configPath}中配置auto=true\n"
        
        read -p "请输入要签名apk的路径：" -e inputApkPath
        findApkArray[0]=$inputApkPath #手动指定apk
    else
        # auto!=false或者auto!=true，就会执行这里
        echo -e "\n---------------警告----------------"
        echo -e "${configPath}配置中auto=${auto}，需要选择要执行的的方式，
                \n如果配置auto=true则自动搜索，auto=false则手动输入。"
        echo -e "---------------警告----------------\n"
        
        # 选择方式
        echo ""
        read -n1 -p "是否自动搜索指定目录(如果没指定搜索目录，默认搜索当前目录)下的apk，否则要手动指定apk路径, [Y/N]?" answer
        case $answer in
        Y | y)
            # 3、自动搜索apk
            echo -e "\n开始自动搜索${findPath}目录下的apk"
            findApk $findPath "*.apk" 
            ;;
        N | n)
            # 4、手动指定apk路径
            echo -e "\n"
            read -p "请输入要签名apk的路径：" -e inputApkPath
            findApkArray[0]=$inputApkPath 
            ;;
        *)
            echo -e "\n"
            echo "选择错误:$answer"
            ;;
        esac
    fi
}

# 循环执行签名apk
function processApk()
{
    for apk in ${findApkArray[@]}
    do
        let tatalTimes++
        echo -e "\n\n准备开始签名第${tatalTimes}个Apk =$apk"
        signAndroidApk $apk $configOutPath
    done

    #不需要循环数组，直接使用数组中最后一个结果进行签名
    #let tatalTimes++
    #signAndroidApk $findApkLastResult
    success=`expr ${tatalTimes} - ${errorTimes}` # 计算成功的次数

    echo -e "\n一共找到${tatalTimes}个apk，成功签名${success}个,失败${errorTimes}个!\n"
}

# 程序运行入口

# 1、获取配置文件的内容
 findConfigFile

# 2、搜索apk（根据配置内容选择要获取apk的方式）
 getApk

# 3、开始处理apk签名
 processApk




 


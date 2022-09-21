const fs = require("fs");
const path = require("path");

const pluginId = "com-outsystems-minsdkversionchanger";

module.exports = function(context) {
    function getPlatformVersion(context) {
        var projectRoot = context.opts.projectRoot;
    
        var packageJsonFile = path.join(
            projectRoot,
            "package.json"
        );
    
        var devDependencies = require(packageJsonFile).devDependencies;
    
        if(devDependencies !== undefined){
            //Probably MABS7
            var platform = devDependencies["cordova-android"];
            if (platform.includes('^')){
                var index = platform.indexOf('^');
                platform = platform.slice(0, index) + platform.slice(index+1);
            }
            if (platform.includes('#')){
                var index = platform.indexOf('#');
                platform = platform.slice(index+1);
            }
            if (platform.includes('+')){
                var index = platform.indexOf('+');
                platform = platform.slice(0,index);
            }
            return platform;
        } else {
            //Probably MABS6.X
            var platformsJsonFile = path.join(
                projectRoot,
                "platforms",
                "platforms.json"
            );
            var platforms = require(platformsJsonFile);
            var platform = context.opts.plugin.platform;
            return platforms[platform];
        }    
    }

    console.log("Changing Android!")
    
    const androidCordovaVersion = parseInt(getPlatformVersion(context));
    if(androidCordovaVersion >= 10){
        console.log("Detected MABS 8 or above!")

        var pathConfig = path.join(
            context.opts.projectRoot,
            "platforms",
            "android",
            "cdv-gradle-config.json"
        );
        

        var content = fs.readFileSync(pathConfig,"utf-8");

        var contentJSON = JSON.parse(content);
        contentJSON.IS_GRADLE_PLUGIN_GOOGLE_SERVICES_ENABLED = false;
        content = JSON.stringify(contentJSON);

        fs.writeFileSync(pathConfig,content);
        console.log("Changed Android MinSDKVersion!")
    }
};
#!/bin/bash


DownloadURL='https://minecraft.azureedge.net/bin-linux/'
ServerVersions=""

if [ ! -z "$(ls -A /var/games/minecraft/profiles)" ]; then
    ServerVersions=$(find /var/games/minecraft/profiles/**/*.zip | sed 's#.*/##')
fi

curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.33 (KHTML, like Gecko) Chrome/90.0.$RandNum.212 Safari/537.33" -s -o ./version.html https://www.minecraft.net/en-us/download/server/bedrock
LatestVersion=$(grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' ./version.html | sed 's#.*/##')

if [[ $ServerVersions == "" || ! $ServerVersions =~ $LatestVersion ]]; then
    ServerVersions+=$LatestVersion
    version_without_extension=$(echo "${LatestVersion%.*}")
    mkdir -p /var/games/minecraft/profiles/$version_without_extension
    curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.33 (KHTML, like Gecko) Chrome/90.0.$RandNum.212 Safari/537.33" -o "/var/games/minecraft/profiles/$version_without_extension/$LatestVersion" "$DownloadURL$LatestVersion"
    7z x -y -aoa -o"/var/games/minecraft/profiles/$version_without_extension/" "/var/games/minecraft/profiles/$version_without_extension/$LatestVersion"
fi

Version_Text=""

for version in $ServerVersions
do
    version_without_extension=$(echo "${version%.*}")
    version_number=$(echo "$version_without_extension" | sed 's/.*-//')
    read -r -d '' text <<- EOM
      item['id'] = '$version_without_extension';
      item['type'] = 'release';
      item['group'] = 'bedrock-server';
      item['webui_desc'] = '$version_number Linux x64 release';
      item['weight'] = 0;
      item['filename'] = '$version';
      item['downloaded'] = fs.existsSync(path.join(profile_dir, item.id, item.filename));
      item['version'] = 0;
      item['release_version'] = '$version_number';
      item['url'] = '$DownloadURL$version';
      p.push(JSON.parse(JSON.stringify(item)));
EOM
      Version_Text+="
      $text
      "
done

cat > "/usr/games/minecraft/profiles.d/bedrock-server.js" <<- EOM

var path = require('path');
var fs = require('fs-extra');
var profile = require('./template');

exports.profile = {
  name: 'Minecraft Bedrock',
  handler: function (profile_dir, callback) {
    var p = [];

    try {  // BEGIN PARSING LOGIC
      var item = new profile();
      $Version_Text
    } catch (e) { console.error(e); }

    callback(null, p);
  }, //end handler
  postdownload: function (profile_dir, dest_filepath, callback) {

    // perform an async chmod of the unipper extracted bedrock_server binary
    fs.chmod((profile_dir + '/bedrock_server'), 0755);
    callback();
  }
}

EOM

echo "Done updating"

exit 0
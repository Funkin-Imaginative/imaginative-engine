var imagePath:String = 'menus/title/intro-texts';
var backseatingAssets = ArrayUtil.recycle();

function onCreatePost():Void {
	// TODO: code this better 😭
	for (data in Paths.readFolder(Paths.image('fallback:$imagePath'), ['png'].weaken(), true)) {
		var array = data.directory.split('/'); array.shift();
		data.directory = array.join('/'); array.put();
		if (data.directory.contains('backseating'))
			backseatingAssets.push(data.file);
		Assets.image(data.toString(), true, 'vulnerable', true);
	}
}

function uponIntroImage(introText:String, imageAsset:ModPath):ModPath {
	if (introText.endsWith('you\'re genocides'))
		return 'fallback:$imagePath/genocides';
	if (introText.startsWith('Hey guys, it\'s me') || introText.endsWith('The Flower Man')) {
		if (introText.endsWith('Rodney!')) return 'fallback:credits/rodney';
		return 'fallback:$imagePath/flowery';
	}
	if (introText.endsWith('Rodney Butt Image'))
		return 'fallback:$imagePath/rodney-butt-image${FlxG.random.bool() ? 'NEW' : ''}';
	if (introText.endsWith('Rodney\'s ideas'))
		return 'fallback:$imagePath/rodney-idea';
	if (introText.startsWith('unauthorized') && introText.endsWith('fucking thing'))
		return 'fallback:$imagePath/unauthorized';
	if (introText.startsWith('never backseat') && introText.endsWith('an artist'))
		return 'fallback:$imagePath/backseating/${FlxG.random.getObject(backseatingAssets)}';
}

function onEnd():Void {
	backseatingAssets.put();
}
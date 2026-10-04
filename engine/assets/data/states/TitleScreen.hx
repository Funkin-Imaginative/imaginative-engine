var imagePath:String = 'menus/title/intro-texts/';

function uponIntroImage(introText:String, imageAsset:ModPath):ModPath {
	if (introText.endsWith('you\'re genocides'))
		return 'main:$imagePath/genocides';
	if (introText.startsWith('Hey guys, it\'s me') || introText.endsWith('The Flower Man')) {
		if (introText.endsWith('Rodney!')) return 'main:credits/rodney';
		return 'main:$imagePath/flowery';
	}
	if (introText.endsWith('Rodney Butt Image'))
		return 'main:$imagePath/rodney-butt-image${FlxG.random.bool() ? 'NEW' : ''}';
}
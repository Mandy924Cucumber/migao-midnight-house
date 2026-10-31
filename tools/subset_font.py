"""Run with: uv run --with fonttools python tools/subset_font.py /path/to/NotoSansCJKsc-Regular.otf"""
import sys
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools import subset

project = Path(__file__).resolve().parents[1]
text = ''.join(path.read_text() for path in (project / 'scripts').glob('*.gd'))
text += ''.join(chr(c) for c in range(32, 127)) + '←→✓○—·：，。！？（）「」『』'
font = TTFont(sys.argv[1])
options = subset.Options()
options.name_IDs = ['*']
subsetter = subset.Subsetter(options=options)
subsetter.populate(text=text)
subsetter.subset(font)
font.save(project / 'assets/fonts/story.ttf')
print('Updated bundled OFL font subset.')

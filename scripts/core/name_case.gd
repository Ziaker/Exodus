class_name NameCase
extends RefCounted

## D-110 (criador 2026-11-26): "tira todos nomes em maiusculo deixa apenas a primeira letra
## assim como yoch", na tela de batalha toda. Each all-caps word of a name keeps only its first
## letter in upper case ("FALLEN" -> "Fallen", "FOE A" -> "Foe A", "HEAT WAVE" -> "Heat Wave",
## "SHUTEN-DOUJI" -> "Shuten-Douji", "AARON'S ROD" -> "Aaron's Rod"). Words already in mixed
## case ("Yoch", "Ra'am") and single letters ("A") stay as they are. The data keeps its
## original spelling; only what is drawn on screen changes.
static func of(text: String) -> String:
	var words := text.split(" ", true)
	for i in words.size():
		var parts := words[i].split("-", true)
		for j in parts.size():
			parts[j] = _word(parts[j])
		words[i] = "-".join(parts)
	return " ".join(words)


static func _word(word: String) -> String:
	if word.length() < 2 or word != word.to_upper() or word == word.to_lower():
		return word
	return word.left(1) + word.substr(1).to_lower()

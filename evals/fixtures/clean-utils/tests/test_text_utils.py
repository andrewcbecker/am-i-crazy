from src.text_utils import slugify


def test_basic_conversion():
    assert slugify("Hello World") == "hello-world"


def test_whitespace_runs():
    assert slugify("a   b\t c") == "a-b-c"


def test_punctuation():
    assert slugify("Rock & Roll!") == "rock-roll"


def test_empty_string():
    assert slugify("") == ""

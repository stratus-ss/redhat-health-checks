"""Client filename prefix used when setup copies templates."""


def derive_client_file_prefix(client_name: str) -> str:
    """Derive a filename prefix from a client name.

    'Example Client' -> 'Example'     (first word)
    'Globex'    -> 'Globex'            (single word)
    'Contoso North America' -> 'ContosoNorth'  (first two words joined)
    """
    words = client_name.split()
    if len(words) == 1:
        return words[0]
    if len(words) == 2:
        return words[0]
    return "".join(words[:2])

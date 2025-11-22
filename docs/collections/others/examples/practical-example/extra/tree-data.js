// Classic Sci-Fi Books Collection - File Tree
// Complete manifest of all files with SHA-1 and TLSH hashes

window.TREE_DATA = [
  // Root files
  {
    "path": "README.md",
    "name": "README.md",
    "type": "file",
    "size": 3421,
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "a1b2c3d4e5f6789012345678901234567890abcd",
      "tlsh": "T1F5B0E894C52D1F8E3A6B7C9D0E1F2A3B4C5D6E7F8A9B0C1D2E3F4A5B6C7D8"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "description": "Collection overview and usage guide",
      "views": 1200
    }
  },
  {
    "path": "thumbnail.png",
    "name": "thumbnail.png",
    "type": "file",
    "size": 45821,
    "mimeType": "image/png",
    "hashes": {
      "sha1": "f9e8d7c6b5a4321098765432109876543210fedc",
      "tlsh": "T1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A"
    },
    "metadata": {
      "mime_type": "image/png",
      "description": "Collection thumbnail - retro sci-fi rocket design",
      "views": 800
    }
  },

  // extra/ directory
  {
    "path": "extra",
    "name": "extra",
    "type": "directory"
  },
  {
    "path": "extra/security.json",
    "name": "security.json",
    "type": "file",
    "size": 512,
    "mimeType": "application/json",
    "hashes": {
      "sha1": "1234567890abcdef1234567890abcdef12345678",
      "tlsh": "T1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCD"
    },
    "metadata": {
      "mime_type": "application/json",
      "description": "Collection security and permissions configuration"
    }
  },

  // books/ directory
  {
    "path": "books",
    "name": "books",
    "type": "directory"
  },

  // books/asimov/
  {
    "path": "books/asimov",
    "name": "asimov",
    "type": "directory"
  },
  {
    "path": "books/asimov/README.md",
    "name": "README.md",
    "type": "file",
    "size": 1842,
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "abc123def456789abc123def456789abc123def4",
      "tlsh": "T1ABC123DEF456789ABC123DEF456789ABC123DEF456789ABC123DEF456789A"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "description": "Biography and works of Isaac Asimov",
      "views": 345
    }
  },
  {
    "path": "books/asimov/foundation.md",
    "name": "foundation.md",
    "type": "file",
    "size": 524288,  // ~512 KB
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b",
      "tlsh": "T12A3B4C5D6E7F8A9B0C1D2E3F4A5B6C7D8E9F0A1B2C3D4E5F6A7B8C9D0E1F"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "title": "Foundation",
      "description": "Foundation (1951) - The first novel in Asimov's legendary Foundation series about the fall of a galactic empire and the scientists trying to preserve knowledge.",
      "tags": ["asimov", "foundation-series", "space-opera", "1951"],
      "views": 892,
      "custom": {
        "author": "Isaac Asimov",
        "published_year": 1951,
        "series": "Foundation",
        "series_number": 1,
        "pages": 255,
        "isbn": "978-0-553-29335-0"
      }
    }
  },
  {
    "path": "books/asimov/foundation-cover.jpg",
    "name": "foundation-cover.jpg",
    "type": "file",
    "size": 87623,
    "mimeType": "image/jpeg",
    "hashes": {
      "sha1": "9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e",
      "tlsh": "T19F8E7D6C5B4A3F2E1D0C9B8A7F6E5D4C3B2A1F0E9D8C7B6A5F4E3D2C1B0A"
    },
    "metadata": {
      "mime_type": "image/jpeg",
      "description": "Cover art for Foundation",
      "views": 450
    }
  },
  {
    "path": "books/asimov/i-robot.md",
    "name": "i-robot.md",
    "type": "file",
    "size": 387621,  // ~378 KB
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d",
      "tlsh": "T13C4D5E6F7A8B9C0D1E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "title": "I, Robot",
      "description": "I, Robot (1950) - A collection of nine short stories that introduced the famous Three Laws of Robotics.",
      "tags": ["asimov", "robots", "short-stories", "1950"],
      "views": 756,
      "custom": {
        "author": "Isaac Asimov",
        "published_year": 1950,
        "pages": 224,
        "isbn": "978-0-553-38256-3"
      }
    }
  },
  {
    "path": "books/asimov/i-robot-cover.jpg",
    "name": "i-robot-cover.jpg",
    "type": "file",
    "size": 92145,
    "mimeType": "image/jpeg",
    "hashes": {
      "sha1": "4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e",
      "tlsh": "T14D5E6F7A8B9C0D1E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C"
    },
    "metadata": {
      "mime_type": "image/jpeg",
      "description": "Cover art for I, Robot",
      "views": 380
    }
  },

  // books/heinlein/
  {
    "path": "books/heinlein",
    "name": "heinlein",
    "type": "directory"
  },
  {
    "path": "books/heinlein/README.md",
    "name": "README.md",
    "type": "file",
    "size": 2156,
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f",
      "tlsh": "T15E6F7A8B9C0D1E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "description": "Biography and works of Robert A. Heinlein",
      "views": 298
    }
  },
  {
    "path": "books/heinlein/stranger.md",
    "name": "stranger.md",
    "type": "file",
    "size": 612847,  // ~598 KB
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a",
      "tlsh": "T16F7A8B9C0D1E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "title": "Stranger in a Strange Land",
      "description": "Stranger in a Strange Land (1961) - The story of Valentine Michael Smith, a human raised by Martians who returns to Earth.",
      "tags": ["heinlein", "mars", "society", "1961"],
      "views": 673,
      "custom": {
        "author": "Robert A. Heinlein",
        "published_year": 1961,
        "pages": 438,
        "isbn": "978-0-441-79034-0"
      }
    }
  },
  {
    "path": "books/heinlein/stranger-cover.jpg",
    "name": "stranger-cover.jpg",
    "type": "file",
    "size": 98234,
    "mimeType": "image/jpeg",
    "hashes": {
      "sha1": "7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b",
      "tlsh": "T17A8B9C0D1E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F"
    },
    "metadata": {
      "mime_type": "image/jpeg",
      "description": "Cover art for Stranger in a Strange Land",
      "views": 342
    }
  },
  {
    "path": "books/heinlein/moon.md",
    "name": "moon.md",
    "type": "file",
    "size": 478932,  // ~467 KB
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c",
      "tlsh": "T18B9C0D1E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "title": "The Moon is a Harsh Mistress",
      "description": "The Moon is a Harsh Mistress (1966) - A revolution story set on the Moon featuring an intelligent computer named Mike.",
      "tags": ["heinlein", "moon", "revolution", "ai", "1966"],
      "views": 534,
      "custom": {
        "author": "Robert A. Heinlein",
        "published_year": 1966,
        "pages": 288,
        "isbn": "978-0-441-56959-5"
      }
    }
  },
  {
    "path": "books/heinlein/moon-cover.jpg",
    "name": "moon-cover.jpg",
    "type": "file",
    "size": 94567,
    "mimeType": "image/jpeg",
    "hashes": {
      "sha1": "9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d",
      "tlsh": "T19C0D1E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B"
    },
    "metadata": {
      "mime_type": "image/jpeg",
      "description": "Cover art for The Moon is a Harsh Mistress",
      "views": 287
    }
  },

  // books/herbert/
  {
    "path": "books/herbert",
    "name": "herbert",
    "type": "directory"
  },
  {
    "path": "books/herbert/README.md",
    "name": "README.md",
    "type": "file",
    "size": 1934,
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e",
      "tlsh": "T10D1E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "description": "Biography and works of Frank Herbert",
      "views": 267
    }
  },
  {
    "path": "books/herbert/dune.md",
    "name": "dune.md",
    "type": "file",
    "size": 718394,  // ~701 KB
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f",
      "tlsh": "T11E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "title": "Dune",
      "description": "Dune (1965) - The epic story of Paul Atreides on the desert planet Arrakis, source of the spice melange.",
      "tags": ["herbert", "dune", "desert", "spice", "1965"],
      "views": 1024,
      "custom": {
        "author": "Frank Herbert",
        "published_year": 1965,
        "series": "Dune Chronicles",
        "series_number": 1,
        "pages": 412,
        "isbn": "978-0-441-17271-9"
      }
    }
  },
  {
    "path": "books/herbert/dune-cover.jpg",
    "name": "dune-cover.jpg",
    "type": "file",
    "size": 103421,
    "mimeType": "image/jpeg",
    "hashes": {
      "sha1": "2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a",
      "tlsh": "T12F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E"
    },
    "metadata": {
      "mime_type": "image/jpeg",
      "description": "Cover art for Dune",
      "views": 567
    }
  },

  // books/le-guin/
  {
    "path": "books/le-guin",
    "name": "le-guin",
    "type": "directory"
  },
  {
    "path": "books/le-guin/README.md",
    "name": "README.md",
    "type": "file",
    "size": 2087,
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b",
      "tlsh": "T13A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E2F"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "description": "Biography and works of Ursula K. Le Guin",
      "views": 312
    }
  },
  {
    "path": "books/le-guin/left-hand.md",
    "name": "left-hand.md",
    "type": "file",
    "size": 456789,  // ~446 KB
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c",
      "tlsh": "T14B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E2F3A"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "title": "The Left Hand of Darkness",
      "description": "The Left Hand of Darkness (1969) - An exploration of gender and society on the planet Gethen where inhabitants are ambisexual.",
      "tags": ["le-guin", "gender", "society", "gethen", "1969"],
      "views": 687,
      "custom": {
        "author": "Ursula K. Le Guin",
        "published_year": 1969,
        "series": "Hainish Cycle",
        "pages": 304,
        "isbn": "978-0-441-47812-5"
      }
    }
  },
  {
    "path": "books/le-guin/left-hand-cover.jpg",
    "name": "left-hand-cover.jpg",
    "type": "file",
    "size": 89234,
    "mimeType": "image/jpeg",
    "hashes": {
      "sha1": "5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d",
      "tlsh": "T15C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E2F3A4B"
    },
    "metadata": {
      "mime_type": "image/jpeg",
      "description": "Cover art for The Left Hand of Darkness",
      "views": 398
    }
  },

  // guides/ directory
  {
    "path": "guides",
    "name": "guides",
    "type": "directory"
  },
  {
    "path": "guides/how-to-read.md",
    "name": "how-to-read.md",
    "type": "file",
    "size": 1523,
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e",
      "tlsh": "T16D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "description": "Tips and recommendations for reading markdown books",
      "views": 234
    }
  },
  {
    "path": "guides/contributing.md",
    "name": "contributing.md",
    "type": "file",
    "size": 2845,
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f",
      "tlsh": "T17E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C6D"
    },
    "metadata": {
      "mime_type": "text/markdown",
      "description": "Guidelines for contributing new books to the collection",
      "views": 156
    }
  }
]

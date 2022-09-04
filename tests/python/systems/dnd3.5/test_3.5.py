#!/usr/bin/env python3

import pytest
from util import roll, Mock

def test_3_5_age():
    # Age for an old Gnome 
    result = roll("150+3d%")
    assert result >= 203
    assert result <= 230

def test_3_5_height():
    # Height for a female Gnome 
    result = roll("34+2d4")
    assert result >= 36
    assert result <= 42

def test_3_5_weight():
    # Weight for a female Gnome
    result = roll("40x1")
    assert result == 40
    
    # Weight for a male half-elf
    result = roll("100x2d4")
    assert result >= 200
    assert result <= 800

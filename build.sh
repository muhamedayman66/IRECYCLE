#!/bin/bash

# حمل Cecil
curl -sSOL https://cecil.app/cecil.phar
chmod +x cecil.phar

# شغّل البناء
php cecil.phar build
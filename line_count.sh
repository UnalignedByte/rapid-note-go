#!/bin/bash

find . \( ! -path ./Rapid\ Note\ Go/Source/Utils/APXML/\* \) -a \( ! -path ./Rapid\ Note\ Go/Source/Utils/IXPickerOverlayView/\* \) -a \( ! -path ./Rapid\ Note\ Go/Source/Utils/KSCustomPopoverBackgroundView/\* \) -a \( ! -path ./Rapid\ Note\ Go/Source/Utils/LTKPopoverActionSheet/\* \) -name "*.[hm]" -print0 | xargs -0 wc -l

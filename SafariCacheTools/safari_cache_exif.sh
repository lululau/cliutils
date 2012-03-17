#!/bin/bash

if [[ $# -ne 1 ]]; then
	exit 1
fi

if grep -Pvq '^http://' <<< "$1"; then
	exit 1
fi

safari_cq "$1" | exiftool - | perl -pe '
s#[^\x0-\x7F]##g;
s#^Camera Model Name\s*?:#01相机#g;
s#^Lens\s*?:#02镜头:#g;
s#^Exposure Time\s*?:#03曝光时间:#g;
s#^Exposure Mode\s*?:#04曝光模式:#g;
s#^Metering Mode\s*?:#05测光模式:#g;
s#^Flash\s*?:#06闪光灯:#g;
s#^F Number\s*?:#07光圈值:#g;
s#^Focal Length\s*?:#08焦距:#g;
s#^ISO\s*?:#09ISO:#g;
s#^AE Setting\s*?:#10曝光补偿:#g;
s#^White Balance\s*?:#11白平衡:#g;
s#^Software\s*?:#12软件:#g;
s#^Date/Time Original\s*?:#13时间:#g;
s#^Image Size\s*?:#14尺寸#g;
' | grep -P '^\d\d' | LC_ALL=C sort | perl -pe 's#^\d\d##' 
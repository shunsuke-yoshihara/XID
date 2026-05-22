# NETLIST Parser
# Design Compiler Setup 
source /gdsfs/gdsfs/cad/env/syn/U-2022.12.env
#ln -s ~ohtake/cad/env/.synopsys_dc.setup .
#mkdir work

#Define Value
echo "Define Value"
set XID=../tcl/X_Identification.tcl
set CIRCUIT=b14
echo "Define Value : OK"

# Time Stamp
setenv TIMESTAMP `date +%m%d%H%M`


# Call Design Compiler
echo "Call Design Compiler"
mkdir -p ../report/${CIRCUIT}/dc
dc_shell -64 -f ${XID} > ../report/${CIRCUIT}/dc/XID_${TIMESTAMP}.log
echo "End of Netlist Parse"


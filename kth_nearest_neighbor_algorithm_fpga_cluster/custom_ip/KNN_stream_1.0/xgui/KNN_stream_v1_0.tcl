# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  set C_S00_AXIS_TDATA_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXIS_TDATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {AXI4Stream sink: Data Width} ${C_S00_AXIS_TDATA_WIDTH}

  set i [ipgui::add_param $IPINST -name "i"]
  set_property tooltip {integers input to knn at once} ${i}
  set d [ipgui::add_param $IPINST -name "d"]
  set_property tooltip {dimensions per vector} ${d}
  set k [ipgui::add_param $IPINST -name "k"]
  set_property tooltip {k nearest neighbors} ${k}
  set o [ipgui::add_param $IPINST -name "o"]
  set_property tooltip {integers output at once} ${o}

}

proc update_PARAM_VALUE.d { PARAM_VALUE.d } {
	# Procedure called to update d when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.d { PARAM_VALUE.d } {
	# Procedure called to validate d
	return true
}

proc update_PARAM_VALUE.i { PARAM_VALUE.i } {
	# Procedure called to update i when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.i { PARAM_VALUE.i } {
	# Procedure called to validate i
	return true
}

proc update_PARAM_VALUE.k { PARAM_VALUE.k } {
	# Procedure called to update k when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.k { PARAM_VALUE.k } {
	# Procedure called to validate k
	return true
}

proc update_PARAM_VALUE.o { PARAM_VALUE.o } {
	# Procedure called to update o when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.o { PARAM_VALUE.o } {
	# Procedure called to validate o
	return true
}

proc update_PARAM_VALUE.p { PARAM_VALUE.p } {
	# Procedure called to update p when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.p { PARAM_VALUE.p } {
	# Procedure called to validate p
	return true
}

proc update_PARAM_VALUE.s { PARAM_VALUE.s } {
	# Procedure called to update s when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.s { PARAM_VALUE.s } {
	# Procedure called to validate s
	return true
}

proc update_PARAM_VALUE.z { PARAM_VALUE.z } {
	# Procedure called to update z when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.z { PARAM_VALUE.z } {
	# Procedure called to validate z
	return true
}

proc update_PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to update C_S00_AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to validate C_S00_AXIS_TDATA_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.i { MODELPARAM_VALUE.i PARAM_VALUE.i } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.i}] ${MODELPARAM_VALUE.i}
}

proc update_MODELPARAM_VALUE.d { MODELPARAM_VALUE.d PARAM_VALUE.d } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.d}] ${MODELPARAM_VALUE.d}
}

proc update_MODELPARAM_VALUE.k { MODELPARAM_VALUE.k PARAM_VALUE.k } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.k}] ${MODELPARAM_VALUE.k}
}

proc update_MODELPARAM_VALUE.s { MODELPARAM_VALUE.s PARAM_VALUE.s } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.s}] ${MODELPARAM_VALUE.s}
}

proc update_MODELPARAM_VALUE.p { MODELPARAM_VALUE.p PARAM_VALUE.p } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.p}] ${MODELPARAM_VALUE.p}
}

proc update_MODELPARAM_VALUE.z { MODELPARAM_VALUE.z PARAM_VALUE.z } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.z}] ${MODELPARAM_VALUE.z}
}

proc update_MODELPARAM_VALUE.o { MODELPARAM_VALUE.o PARAM_VALUE.o } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.o}] ${MODELPARAM_VALUE.o}
}


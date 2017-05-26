# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  set RD_BITS [ipgui::add_param $IPINST -name "RD_BITS"]
  set_property tooltip {The amount of bits to be read from BRAM.} ${RD_BITS}

}

proc update_PARAM_VALUE.RD_BITS { PARAM_VALUE.RD_BITS } {
	# Procedure called to update RD_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RD_BITS { PARAM_VALUE.RD_BITS } {
	# Procedure called to validate RD_BITS
	return true
}


proc update_MODELPARAM_VALUE.RD_BITS { MODELPARAM_VALUE.RD_BITS PARAM_VALUE.RD_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RD_BITS}] ${MODELPARAM_VALUE.RD_BITS}
}


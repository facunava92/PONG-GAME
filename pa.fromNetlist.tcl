
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name Pong_FSM -dir "C:/Users/facun/OneDrive/Proyecyo_Tecnicas/Xiling/Pong_FSM/Pong_FSM/planAhead_run_2" -part xc3s100etq144-5
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/facun/OneDrive/Proyecyo_Tecnicas/Xiling/Pong_FSM/Pong_FSM/pong_top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/facun/OneDrive/Proyecyo_Tecnicas/Xiling/Pong_FSM/Pong_FSM} }
set_property target_constrs_file "pong_top.ucf" [current_fileset -constrset]
add_files [list {pong_top.ucf}] -fileset [get_property constrset [current_run]]
link_design

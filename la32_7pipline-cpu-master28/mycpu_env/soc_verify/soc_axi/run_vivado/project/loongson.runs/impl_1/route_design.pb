
Q
Command: %s
53*	vivadotcl2 
route_design2default:defaultZ4-113h px� 
�
@Attempting to get a license for feature '%s' and/or device '%s'
308*common2"
Implementation2default:default2
xc7a200t2default:defaultZ17-347h px� 
�
0Got license for feature '%s' and/or device '%s'
310*common2"
Implementation2default:default2
xc7a200t2default:defaultZ17-349h px� 
P
Running DRC with %s threads
24*drc2
82default:defaultZ23-27h px� 
V
DRC finished with %s
79*	vivadotcl2
0 Errors2default:defaultZ4-198h px� 
e
BPlease refer to the DRC report (report_drc) for more information.
80*	vivadotclZ4-199h px� 
p
,Running DRC as a precondition to command %s
22*	vivadotcl2 
route_design2default:defaultZ4-22h px� 
P
Running DRC with %s threads
24*drc2
82default:defaultZ23-27h px� 
V
DRC finished with %s
79*	vivadotcl2
0 Errors2default:defaultZ4-198h px� 
e
BPlease refer to the DRC report (report_drc) for more information.
80*	vivadotclZ4-199h px� 
V

Starting %s Task
103*constraints2
Routing2default:defaultZ18-103h px� 
}
BMultithreading enabled for route_design using a maximum of %s CPUs17*	routeflow2
82default:defaultZ35-254h px� 
p

Phase %s%s
101*constraints2
1 2default:default2#
Build RT Design2default:defaultZ18-101h px� 
B
-Phase 1 Build RT Design | Checksum: 99bc5b9c
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:00:47 ; elapsed = 00:00:35 . Memory (MB): peak = 3460.957 ; gain = 0.000 ; free physical = 744 ; free virtual = 78212default:defaulth px� 
v

Phase %s%s
101*constraints2
2 2default:default2)
Router Initialization2default:defaultZ18-101h px� 
o

Phase %s%s
101*constraints2
2.1 2default:default2 
Create Timer2default:defaultZ18-101h px� 
A
,Phase 2.1 Create Timer | Checksum: 99bc5b9c
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:00:47 ; elapsed = 00:00:36 . Memory (MB): peak = 3460.957 ; gain = 0.000 ; free physical = 747 ; free virtual = 78242default:defaulth px� 
{

Phase %s%s
101*constraints2
2.2 2default:default2,
Fix Topology Constraints2default:defaultZ18-101h px� 
M
8Phase 2.2 Fix Topology Constraints | Checksum: 99bc5b9c
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:00:47 ; elapsed = 00:00:36 . Memory (MB): peak = 3460.957 ; gain = 0.000 ; free physical = 705 ; free virtual = 77822default:defaulth px� 
t

Phase %s%s
101*constraints2
2.3 2default:default2%
Pre Route Cleanup2default:defaultZ18-101h px� 
F
1Phase 2.3 Pre Route Cleanup | Checksum: 99bc5b9c
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:00:47 ; elapsed = 00:00:36 . Memory (MB): peak = 3460.957 ; gain = 0.000 ; free physical = 705 ; free virtual = 77822default:defaulth px� 
p

Phase %s%s
101*constraints2
2.4 2default:default2!
Update Timing2default:defaultZ18-101h px� 
C
.Phase 2.4 Update Timing | Checksum: 161fc9505
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:01:05 ; elapsed = 00:00:43 . Memory (MB): peak = 3460.957 ; gain = 0.000 ; free physical = 679 ; free virtual = 77562default:defaulth px� 
�
Intermediate Timing Summary %s164*route2K
7| WNS=-1.246 | TNS=-526.298| WHS=-0.148 | THS=-77.108|
2default:defaultZ35-416h px� 
}

Phase %s%s
101*constraints2
2.5 2default:default2.
Update Timing for Bus Skew2default:defaultZ18-101h px� 
r

Phase %s%s
101*constraints2
2.5.1 2default:default2!
Update Timing2default:defaultZ18-101h px� 
E
0Phase 2.5.1 Update Timing | Checksum: 20835bba2
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:01:18 ; elapsed = 00:00:46 . Memory (MB): peak = 3460.957 ; gain = 0.000 ; free physical = 677 ; free virtual = 77542default:defaulth px� 
�
Intermediate Timing Summary %s164*route2K
7| WNS=-1.246 | TNS=-421.331| WHS=N/A    | THS=N/A    |
2default:defaultZ35-416h px� 
P
;Phase 2.5 Update Timing for Bus Skew | Checksum: 151aa80f4
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:01:18 ; elapsed = 00:00:46 . Memory (MB): peak = 3460.957 ; gain = 0.000 ; free physical = 676 ; free virtual = 77532default:defaulth px� 
I
4Phase 2 Router Initialization | Checksum: 119459170
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:01:18 ; elapsed = 00:00:46 . Memory (MB): peak = 3460.957 ; gain = 0.000 ; free physical = 676 ; free virtual = 77532default:defaulth px� 
p

Phase %s%s
101*constraints2
3 2default:default2#
Initial Routing2default:defaultZ18-101h px� 
C
.Phase 3 Initial Routing | Checksum: 2088549ab
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:04:14 ; elapsed = 00:01:22 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 641 ; free virtual = 77182default:defaulth px� 
s

Phase %s%s
101*constraints2
4 2default:default2&
Rip-up And Reroute2default:defaultZ18-101h px� 
u

Phase %s%s
101*constraints2
4.1 2default:default2&
Global Iteration 02default:defaultZ18-101h px� 
�
Intermediate Timing Summary %s164*route2L
8| WNS=-1.911 | TNS=-1464.754| WHS=N/A    | THS=N/A    |
2default:defaultZ35-416h px� 
H
3Phase 4.1 Global Iteration 0 | Checksum: 251d22e00
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:11:17 ; elapsed = 00:03:53 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 656 ; free virtual = 77332default:defaulth px� 
u

Phase %s%s
101*constraints2
4.2 2default:default2&
Global Iteration 12default:defaultZ18-101h px� 
�
Intermediate Timing Summary %s164*route2K
7| WNS=-1.711 | TNS=-762.400| WHS=N/A    | THS=N/A    |
2default:defaultZ35-416h px� 
H
3Phase 4.2 Global Iteration 1 | Checksum: 19a2d375d
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:12:58 ; elapsed = 00:04:39 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 660 ; free virtual = 77372default:defaulth px� 
u

Phase %s%s
101*constraints2
4.3 2default:default2&
Global Iteration 22default:defaultZ18-101h px� 
�
Intermediate Timing Summary %s164*route2K
7| WNS=-1.606 | TNS=-663.519| WHS=N/A    | THS=N/A    |
2default:defaultZ35-416h px� 
H
3Phase 4.3 Global Iteration 2 | Checksum: 22bc51349
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:38 ; elapsed = 00:05:50 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 657 ; free virtual = 77342default:defaulth px� 
F
1Phase 4 Rip-up And Reroute | Checksum: 22bc51349
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:38 ; elapsed = 00:05:50 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 657 ; free virtual = 77342default:defaulth px� 
|

Phase %s%s
101*constraints2
5 2default:default2/
Delay and Skew Optimization2default:defaultZ18-101h px� 
p

Phase %s%s
101*constraints2
5.1 2default:default2!
Delay CleanUp2default:defaultZ18-101h px� 
r

Phase %s%s
101*constraints2
5.1.1 2default:default2!
Update Timing2default:defaultZ18-101h px� 
E
0Phase 5.1.1 Update Timing | Checksum: 204eb7e52
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:42 ; elapsed = 00:05:52 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 657 ; free virtual = 77342default:defaulth px� 
�
Intermediate Timing Summary %s164*route2K
7| WNS=-1.519 | TNS=-567.179| WHS=N/A    | THS=N/A    |
2default:defaultZ35-416h px� 
C
.Phase 5.1 Delay CleanUp | Checksum: 23e2d0c7b
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:43 ; elapsed = 00:05:52 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 653 ; free virtual = 77312default:defaulth px� 
z

Phase %s%s
101*constraints2
5.2 2default:default2+
Clock Skew Optimization2default:defaultZ18-101h px� 
M
8Phase 5.2 Clock Skew Optimization | Checksum: 23e2d0c7b
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:43 ; elapsed = 00:05:52 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 653 ; free virtual = 77312default:defaulth px� 
O
:Phase 5 Delay and Skew Optimization | Checksum: 23e2d0c7b
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:43 ; elapsed = 00:05:52 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 653 ; free virtual = 77312default:defaulth px� 
n

Phase %s%s
101*constraints2
6 2default:default2!
Post Hold Fix2default:defaultZ18-101h px� 
p

Phase %s%s
101*constraints2
6.1 2default:default2!
Hold Fix Iter2default:defaultZ18-101h px� 
r

Phase %s%s
101*constraints2
6.1.1 2default:default2!
Update Timing2default:defaultZ18-101h px� 
E
0Phase 6.1.1 Update Timing | Checksum: 1b234f6f1
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:47 ; elapsed = 00:05:54 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 653 ; free virtual = 77312default:defaulth px� 
�
Intermediate Timing Summary %s164*route2K
7| WNS=-1.519 | TNS=-536.555| WHS=0.059  | THS=0.000  |
2default:defaultZ35-416h px� 
C
.Phase 6.1 Hold Fix Iter | Checksum: 200515188
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:48 ; elapsed = 00:05:54 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 653 ; free virtual = 77302default:defaulth px� 
A
,Phase 6 Post Hold Fix | Checksum: 200515188
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:48 ; elapsed = 00:05:54 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 653 ; free virtual = 77302default:defaulth px� 
o

Phase %s%s
101*constraints2
7 2default:default2"
Route finalize2default:defaultZ18-101h px� 
B
-Phase 7 Route finalize | Checksum: 2433577e9
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:48 ; elapsed = 00:05:54 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 652 ; free virtual = 77292default:defaulth px� 
v

Phase %s%s
101*constraints2
8 2default:default2)
Verifying routed nets2default:defaultZ18-101h px� 
I
4Phase 8 Verifying routed nets | Checksum: 2433577e9
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:48 ; elapsed = 00:05:54 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 651 ; free virtual = 77282default:defaulth px� 
r

Phase %s%s
101*constraints2
9 2default:default2%
Depositing Routes2default:defaultZ18-101h px� 
E
0Phase 9 Depositing Routes | Checksum: 1b81d7a95
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:50 ; elapsed = 00:05:56 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 652 ; free virtual = 77302default:defaulth px� 
t

Phase %s%s
101*constraints2
10 2default:default2&
Post Router Timing2default:defaultZ18-101h px� 
�
Estimated Timing Summary %s
57*route2K
7| WNS=-1.519 | TNS=-536.555| WHS=0.059  | THS=0.000  |
2default:defaultZ35-57h px� 
B
!Router estimated timing not met.
128*routeZ35-328h px� 
G
2Phase 10 Post Router Timing | Checksum: 1b81d7a95
*commonh px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:50 ; elapsed = 00:05:56 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 654 ; free virtual = 77312default:defaulth px� 
@
Router Completed Successfully
2*	routeflowZ35-16h px� 
�

%s
*constraints2�
�Time (s): cpu = 00:15:50 ; elapsed = 00:05:56 . Memory (MB): peak = 3463.914 ; gain = 2.957 ; free physical = 720 ; free virtual = 77972default:defaulth px� 
Z
Releasing license: %s
83*common2"
Implementation2default:defaultZ17-83h px� 
�
G%s Infos, %s Warnings, %s Critical Warnings and %s Errors encountered.
28*	vivadotcl2
8222default:default2
562default:default2
332default:default2
02default:defaultZ4-41h px� 
^
%s completed successfully
29*	vivadotcl2 
route_design2default:defaultZ4-42h px� 
�
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2"
route_design: 2default:default2
00:15:542default:default2
00:05:582default:default2
3463.9142default:default2
2.9572default:default2
7202default:default2
77972default:defaultZ17-722h px� 
�
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2.
Netlist sorting complete. 2default:default2
00:00:00.012default:default2
00:00:002default:default2
3463.9142default:default2
0.0002default:default2
7202default:default2
77972default:defaultZ17-722h px� 
H
&Writing timing data to binary archive.266*timingZ38-480h px� 
D
Writing placer database...
1603*designutilsZ20-1893h px� 
=
Writing XDEF routing.
211*designutilsZ20-211h px� 
J
#Writing XDEF routing logical nets.
209*designutilsZ20-209h px� 
J
#Writing XDEF routing special nets.
210*designutilsZ20-210h px� 
�
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2)
Write XDEF Complete: 2default:default2
00:00:062default:default2
00:00:022default:default2
3463.9142default:default2
0.0002default:default2
6632default:default2
77892default:defaultZ17-722h px� 
�
 The %s '%s' has been generated.
621*common2

checkpoint2default:default2�
�/home/ysyx/weihui/la32_7pipline-cpu-master/mycpu_env/soc_verify/soc_axi/run_vivado/project/loongson.runs/impl_1/soc_axi_lite_top_routed.dcp2default:defaultZ17-1381h px� 
�
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2&
write_checkpoint: 2default:default2
00:00:102default:default2
00:00:062default:default2
3463.9142default:default2
0.0002default:default2
7102default:default2
78012default:defaultZ17-722h px� 
�
%s4*runtcl2�
�Executing : report_drc -file soc_axi_lite_top_drc_routed.rpt -pb soc_axi_lite_top_drc_routed.pb -rpx soc_axi_lite_top_drc_routed.rpx
2default:defaulth px� 
�
Command: %s
53*	vivadotcl2�
xreport_drc -file soc_axi_lite_top_drc_routed.rpt -pb soc_axi_lite_top_drc_routed.pb -rpx soc_axi_lite_top_drc_routed.rpx2default:defaultZ4-113h px� 
>
IP Catalog is up to date.1232*coregenZ19-1839h px� 
P
Running DRC with %s threads
24*drc2
82default:defaultZ23-27h px� 
�
#The results of DRC are in file %s.
168*coretcl2�
�/home/ysyx/weihui/la32_7pipline-cpu-master/mycpu_env/soc_verify/soc_axi/run_vivado/project/loongson.runs/impl_1/soc_axi_lite_top_drc_routed.rpt�/home/ysyx/weihui/la32_7pipline-cpu-master/mycpu_env/soc_verify/soc_axi/run_vivado/project/loongson.runs/impl_1/soc_axi_lite_top_drc_routed.rpt2default:default8Z2-168h px� 
\
%s completed successfully
29*	vivadotcl2

report_drc2default:defaultZ4-42h px� 
�
%s4*runtcl2�
�Executing : report_methodology -file soc_axi_lite_top_methodology_drc_routed.rpt -pb soc_axi_lite_top_methodology_drc_routed.pb -rpx soc_axi_lite_top_methodology_drc_routed.rpx
2default:defaulth px� 
�
Command: %s
53*	vivadotcl2�
�report_methodology -file soc_axi_lite_top_methodology_drc_routed.rpt -pb soc_axi_lite_top_methodology_drc_routed.pb -rpx soc_axi_lite_top_methodology_drc_routed.rpx2default:defaultZ4-113h px� 
E
%Done setting XDC timing constraints.
35*timingZ38-35h px� 
Y
$Running Methodology with %s threads
74*drc2
82default:defaultZ23-133h px� 
�
2The results of Report Methodology are in file %s.
450*coretcl2�
�/home/ysyx/weihui/la32_7pipline-cpu-master/mycpu_env/soc_verify/soc_axi/run_vivado/project/loongson.runs/impl_1/soc_axi_lite_top_methodology_drc_routed.rpt�/home/ysyx/weihui/la32_7pipline-cpu-master/mycpu_env/soc_verify/soc_axi/run_vivado/project/loongson.runs/impl_1/soc_axi_lite_top_methodology_drc_routed.rpt2default:default8Z2-1520h px� 
d
%s completed successfully
29*	vivadotcl2&
report_methodology2default:defaultZ4-42h px� 
�
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2(
report_methodology: 2default:default2
00:00:352default:default2
00:00:092default:default2
3551.9572default:default2
0.0002default:default2
6852default:default2
77762default:defaultZ17-722h px� 
�
%s4*runtcl2�
�Executing : report_power -file soc_axi_lite_top_power_routed.rpt -pb soc_axi_lite_top_power_summary_routed.pb -rpx soc_axi_lite_top_power_routed.rpx
2default:defaulth px� 
�
Command: %s
53*	vivadotcl2�
�report_power -file soc_axi_lite_top_power_routed.rpt -pb soc_axi_lite_top_power_summary_routed.pb -rpx soc_axi_lite_top_power_routed.rpx2default:defaultZ4-113h px� 
E
%Done setting XDC timing constraints.
35*timingZ38-35h px� 
K
,Running Vector-less Activity Propagation...
51*powerZ33-51h px� 
P
3
Finished Running Vector-less Activity Propagation
1*powerZ33-1h px� 
�
G%s Infos, %s Warnings, %s Critical Warnings and %s Errors encountered.
28*	vivadotcl2
8342default:default2
562default:default2
332default:default2
02default:defaultZ4-41h px� 
^
%s completed successfully
29*	vivadotcl2 
report_power2default:defaultZ4-42h px� 
�
r%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s ; free physical = %s ; free virtual = %s
480*common2"
report_power: 2default:default2
00:00:222default:default2
00:00:072default:default2
3551.9572default:default2
0.0002default:default2
6522default:default2
77522default:defaultZ17-722h px� 
�
%s4*runtcl2�
mExecuting : report_route_status -file soc_axi_lite_top_route_status.rpt -pb soc_axi_lite_top_route_status.pb
2default:defaulth px� 
�
%s4*runtcl2�
�Executing : report_timing_summary -max_paths 10 -file soc_axi_lite_top_timing_summary_routed.rpt -pb soc_axi_lite_top_timing_summary_routed.pb -rpx soc_axi_lite_top_timing_summary_routed.rpx -warn_on_violation 
2default:defaulth px� 
r
UpdateTimingParams:%s.
91*timing29
% Speed grade: -1, Delay Type: min_max2default:defaultZ38-91h px� 
|
CMultithreading enabled for timing update using a maximum of %s CPUs155*timing2
82default:defaultZ38-191h px� 
�
rThe design failed to meet the timing requirements. Please see the %s report for details on the timing violations.
188*timing2"
timing summary2default:defaultZ38-282h px� 
�
}There are set_bus_skew constraint(s) in this design. Please run report_bus_skew to ensure that bus skew requirements are met.223*timingZ38-436h px� 
�
%s4*runtcl2m
YExecuting : report_incremental_reuse -file soc_axi_lite_top_incremental_reuse_routed.rpt
2default:defaulth px� 
g
BIncremental flow is disabled. No incremental reuse Info to report.423*	vivadotclZ4-1062h px� 
�
%s4*runtcl2m
YExecuting : report_clock_utilization -file soc_axi_lite_top_clock_utilization_routed.rpt
2default:defaulth px� 
�
%s4*runtcl2�
�Executing : report_bus_skew -warn_on_violation -file soc_axi_lite_top_bus_skew_routed.rpt -pb soc_axi_lite_top_bus_skew_routed.pb -rpx soc_axi_lite_top_bus_skew_routed.rpx
2default:defaulth px� 
r
UpdateTimingParams:%s.
91*timing29
% Speed grade: -1, Delay Type: min_max2default:defaultZ38-91h px� 
|
CMultithreading enabled for timing update using a maximum of %s CPUs155*timing2
82default:defaultZ38-191h px� 


End Record
# python3 test.py --gtkwave-fmt 'ghw' --gtkwave-args='--wave=counter.ghw --stop-time=100us'

from vunit import VUnit
vu = VUnit.from_argv()
lib = vu.add_library("counter_lib")
lib.add_source_files(["counter_rtl.vhd","counter_tb.vhd"])
vu.main()

PYTHON ?= python3

.PHONY: starter full repro smoke clean

starter:
	$(PYTHON) -m src.pipeline --scale starter --outdir output/starter

full:
	$(PYTHON) -m src.pipeline --scale full --outdir output/full

full-rerun:
	$(PYTHON) -m src.pipeline --scale full --outdir output/full_rerun

repro: full full-rerun
	$(PYTHON) -m src.pipeline --verify output/full output/full_rerun

smoke:
	$(PYTHON) scripts/smoke_test.py

clean:
	rm -rf output/starter output/full output/full_rerun output/repro_check.md

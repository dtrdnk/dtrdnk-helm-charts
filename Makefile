TMP_DIRECTORY = ./tmp
CHARTS ?= linstor-cluster piraeus tempo-operator tempo-stack

.PHONY: check-examples
check-examples:
	for chart_name in $(CHARTS); do \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \;); \
		for example in $${EXAMPLES}; do \
			echo "Checking example: $${example}"; \
			VALUES=$$(find $${EXAMPLES_DIR}/$${example} -name *values.yaml); \
			for value in $${VALUES}; do \
				helm dependency build charts/$${chart_name}; \
				helm template example charts/$${chart_name} --namespace default --values $${value} --output-dir "${TMP_DIRECTORY}/$${example}"; \
				SUBCHARTS_DIR=${TMP_DIRECTORY}/$${example}/$${chart_name}/charts; \
				SUBCHARTS=$$(find $${SUBCHARTS_DIR} -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \;); \
				for subchart in $${SUBCHARTS}; do \
					mkdir -p "${TMP_DIRECTORY}/$${example}/$${chart_name}/templates/$${subchart}"; \
					mv ${TMP_DIRECTORY}/$${example}/$${chart_name}/charts/$${subchart}/templates/* "${TMP_DIRECTORY}/$${example}/$${chart_name}/templates/$${subchart}"; \
				done; \
			done; \
			if diff -r "$${EXAMPLES_DIR}/$${example}/rendered" "${TMP_DIRECTORY}/$${example}/$${chart_name}/templates" > /dev/null; then \
				echo "Passed $${example}"; \
			else \
				echo "Failed $${example}. run 'make generate-examples' to re-render the example with the latest $${example}/values.yaml"; \
				rm -rf ${TMP_DIRECTORY}; \
				exit 1; \
			fi; \
			rm -rf ${TMP_DIRECTORY}; \
		done; \
	done

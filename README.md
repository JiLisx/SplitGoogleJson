# SplitGoogleJson

## Overview

This repository includes scripts for parsing patent data and research data from Google JSON format.

## Usage

### Patent Parser

```python
from patent_parser import PatentParser

parser = PatentParser()
results = parser.parse("path_to_patent_json")
print(results)
```

### Research Data Parser

```python
from researchdata_parser import ResearchDataParser

parser = ResearchDataParser()
results = parser.parse("path_to_researchdata_json")
print(results)
```

## Installation

To install the required packages, use:

```bash
pip install -r requirements.txt
```

## License

This project is licensed under the MIT License.
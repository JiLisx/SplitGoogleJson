# Splitting Google Patent Public Data JSON Files

This project aims to provide a toolkit for efficiently splitting the Google Patent public data JSON files into smaller, manageable chunks. Google Patents offer a wealth of information in JSON format, which can be extensive and cumbersome to handle in one go. 

## Overview

Google Patents data consists of a large volume of patent documents stored in JSON format. These files can be quite large, making it challenging to process them in their entirety. Our splitting tool allows users to break these files into smaller segments, facilitating easier analysis and processing.

SplitGoogleJson provides two parsers for handling large JSON datasets:

- **Patent Parser** (`patent_parser.py`): Extracts patent information from "patents-public-data.patents.publications", including IPC codes, citations, titles, abstracts, assignees, examiners, inventors, and child patents
- **Research Data Parser** (`researchdata_parser.py`): Processes patent research data from "patents-public-data.patents.google_patents_research", including embeddings and top terms.

## Features
- **Customizable Splitting**: Users can specify the size of the chunks they want to create from the original JSON file.
- **Batch Processing**: The tool allows batch processing of multiple JSON files at once.
- **Easy Integration**: The split files will maintain their structure, ensuring that no data is lost during the process.
- **User-friendly Interface**: Instructions and logs are included to guide users through the splitting process.

## How to Use
1. Clone the repository: `git clone <repository_url>`
2. Navigate to the project directory: `cd SplitGoogleJson`
3. Run the script and specify the JSON file you want to split along with any additional parameters.
4. Check the output directory for the split files.

## Contributions
Contributions to improve the tool or add more features are welcome! Please open an issue for discussion or submit a pull request.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

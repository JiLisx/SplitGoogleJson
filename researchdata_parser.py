import os
import json
import multiprocessing

ipt_dirt = "/Users/liji/Documents/git/SplitGoogleJson/researchdata250202/"
opt_dirt = "/Users/liji/Documents/git/SplitGoogleJson/researchtidydata/"
finished = "finished.txt"

if not os.path.exists(opt_dirt):
    os.makedirs(opt_dirt)

if not os.path.exists(os.path.join(opt_dirt, finished)):
    with open(os.path.join(opt_dirt, finished), 'w') as file:
        pass

def parser(file, ipt_dirt, opt_dirt, finished):
    print(f"Processing: {file}")
    if file.startswith('pt_research_data'):
        with open(ipt_dirt+file, "r") as f:
            for pt in f.readlines():
                patent = json.loads(pt)
                
                if len(patent["embedding_v1"]) > 0:
                    with open(opt_dirt+'embedding.txt','a') as fs:
                        fs.write("{1}{0}{2}\n".format("|",patent["publication_number"],
                                                          patent["embedding_v1"]))

                if len(patent["top_terms"]) > 0:
                    with open(opt_dirt+'top_terms.txt','a') as fs:
                        fs.write("{1}{0}{2}\n".format("|",patent["publication_number"],
                                                          patent["top_terms"]))
                
        with open(os.path.join(opt_dirt, finished), 'a') as fs:
            fs.write(file + '\n')
            

if __name__ == '__main__':
    files = [f for f in os.listdir(ipt_dirt) if f.endswith('.json')]
    with open(os.path.join(opt_dirt, finished), 'r') as f:
        processed_files = set(line.strip() for line in f.readlines())
    
    pool = multiprocessing.Pool(1)
    for file in files:
        if file not in processed_files:
            pool.apply_async(parser, (file, ipt_dirt, opt_dirt, finished))
    
    pool.close()
    pool.join()
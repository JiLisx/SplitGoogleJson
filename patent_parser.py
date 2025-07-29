import os
import re
import json
import multiprocessing

ipt_dirt = "/Users/liji/Documents/git/SplitGoogleJson/publications250125/"
opt_dirt = "/Users/liji/Documents/git/SplitGoogleJson/tidydata/"
finished = "finished_parse250208.txt"

if not os.path.exists(os.path.join(opt_dirt, finished)):
    with open(os.path.join(opt_dirt, finished), 'w') as file:
        pass

def parser(file, ipt_dirt, opt_dirt, finished):
    if file.startswith('ggpatentdata'):
        with open(ipt_dirt+file, "r") as f:
            for pt in f.readlines():
                patent = json.loads(pt)
                '''
                with open(opt_dirt+'app_pub_number.txt','a') as fs:
                    fs.write("{1}{0}{2}{0}{3}{0}{4}{0}{5}{0}{6}\n".format("|", patent["publication_number"],
                                                      patent["application_number"],
                                                      patent["country_code"],
                                                      patent["application_kind"],
                                                      patent["pct_number"],
                                                      patent["family_id"]))
                with open(opt_dirt+'date.txt','a') as fs:
                    fs.write("{1}{0}{2}{0}{3}{0}{4}{0}{5}{0}{6}\n".format("|",patent["publication_number"],
                                                      patent["application_number"],
                                                      patent["publication_date"],
                                                      patent["filing_date"],
                                                      patent["grant_date"],
                                                      patent["priority_date"]))

                if len(patent["claims_localized"]) > 0:
                    claim = {'app_num': patent["application_number"],
                             'claims':patent["claims_localized"][0]["text"]}
                    with open(opt_dirt+'claims.txt','a') as fs:
                        fs.write(json.dumps(claim)+'\n')

                if len(patent["description_localized"]) > 0:
                    descr = {'app_num': patent["application_number"],
                             'descrip':patent["description_localized"][0]["text"]}
                    with open(opt_dirt+'description.txt','a') as fs:
                        fs.write(json.dumps(descr)+'\n')
                '''
                if len(patent["ipc"]) > 0:
                    for ipc in patent["ipc"]:
                        with open(opt_dirt + 'ipc.txt', 'a') as fs:
                            fs.write("{1}{0}{2}\n".format("|",patent["application_number"],
                                                          ipc["code"]))
                '''
                if len(patent["citation"]) > 0:
                    for cite in patent["citation"]:
                        if cite["npl_text"].__len__() > 0:
                            with open(opt_dirt+"npc.txt","a") as fs:
                                fs.write("{1}{0}{2}{0}{3}\n".format("|",patent["publication_number"],
                                                                  cite["npl_text"],cite["category"]))
                        else:
                            with open(opt_dirt+"backward.txt","a") as fs:
                                fs.write("{1}{0}{2}{0}{3}\n".format("|",patent["publication_number"],
                                                                  cite["publication_number"],
                                                                  cite["application_number"],
                                                                  cite["type"],
                                                                  cite["category"]))
               
                
                if len(patent["title_localized"]) > 0 and patent.get("country_code") == "CN" : 
                    for title in patent["title_localized"]:
                        with open(opt_dirt+'title_cn.txt','a') as fs:
                            fs.write("{1}{0}{2}{0}{3}{0}{4}\n".format("|",patent["publication_number"],
                                                              title["language"],
                                                              title["truncated"],
                                                              title["text"]))
                            
                if len(patent["abstract_localized"]) > 0 and patent.get("country_code") == "CN" :
                    for abstract in patent["abstract_localized"]:
                        clean_text = re.sub(r'[|\n]', ' ', abstract.get("text", ""))
                        with open(opt_dirt+'abstract_cn.txt','a') as fs:
                            fs.write("{1}{0}{2}{0}{3}{0}{4}\n".format("|",patent["publication_number"],
                                                              abstract["language"],
                                                              abstract["truncated"],
                                                              clean_text))

                if len(patent["assignee"]) > 0:
                    with open(opt_dirt+'assignee.txt','a') as fs:
                        fs.write("{1}{0}{2}\n".format("|",patent["application_number"],
                                                          patent["assignee"]))
                            
                if len(patent["examiner"]) > 0:
                    for examiner in patent["examiner"]:
                        with open(opt_dirt + 'examiner.txt', 'a') as fs:
                            fs.write("{1}{0}{2}{0}{3}\n".format("|",patent["publication_number"],
                                                                    examiner["name"],
                                                                    examiner["level"]))                     

                if len(patent["inventor"]) > 0:
                    with open(opt_dirt + 'inventor.txt', 'a') as fs:
                        fs.write("{1}{0}{2}\n".format("|",patent["application_number"],
                                                          patent["inventor"]))     
                
                if len(patent["child"]) > 0:
                    for child in patent["child"]:
                        with open(opt_dirt + 'child.txt', 'a') as fs:
                            fs.write("{1}{0}{2}{0}{3}\n".format("|",patent["application_number"],
                                                              child["application_number"],
                                                              child["type"]))
                    '''
        with open(os.path.join(opt_dirt, finished), 'a') as fs:
            fs.write(file+'\n')

if __name__ == '__main__':
    files = os.listdir(ipt_dirt)
    with open(os.path.join(opt_dirt, finished), 'r') as file:
        finish = [line.strip() for line in file.readlines()]
    pool = multiprocessing.Pool(1)
    for file in files:
        print(file)
        if file not in finish:
            pool.apply_async(func=parser, args=(file, ipt_dirt, opt_dirt, finished,))
    pool.close()
    pool.join()
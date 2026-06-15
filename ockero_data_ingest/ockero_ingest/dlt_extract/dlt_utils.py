def run_pipeline(pipeline, source):
    info = pipeline.run(source)
    print_pipeline_info(info, pipeline)


def print_pipeline_info(info,pipeline):
    from datetime import datetime
    start_time = datetime.now().strftime("%H:%M:%S")
    
    print(f"{start_time} Running dlt pipeline")
    print(start_time)
    print(f"{start_time} Pipeline: {pipeline.pipeline_name}") 
    print(f"{start_time} Dataset: {pipeline.dataset_name}") 
    
    for package in info.load_packages:
        print(f"{start_time} Package ID: {package.load_id} | State: {package.state}")

        for table in package.schema.tables:
            completed_jobs = [
                job for job in package.jobs['completed_jobs']
                if job.job_file_info.table_name == table
            ]
            if completed_jobs:
                total_files = len(completed_jobs)
                total_size = sum(job.file_size for job in completed_jobs)
                total_elapsed = sum(job.elapsed for job in completed_jobs)
                print(f"{start_time} Table: {table} | Files: {total_files} | Size: {total_size} bytes | Time: {total_elapsed:.2f}s")
            else:
                print(f"{start_time} Table: {table} | No completed jobs")
        print("-"*50)
    print(start_time)
    print(f"{start_time} Pipeline {pipeline.pipeline_name} finished at {datetime.now().strftime('%H:%M:%S')}")
    print(start_time)
    print(f"{start_time} DONE")





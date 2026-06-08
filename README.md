Welcome to your POINT dbt project!

### Tranforming Point data

Step1. DBT run  
        - Transform all data into marts table
        - Create via macro parquet files of all models inside marts folder
        - Parquet files saves to folder set in profiles.yml

Step2. python scripts/upload_parquet_to_azure.py
        - Upload parquet to Point azure folder point_data_model


### Needs
    - profiles.yml 
        - Key to azure storage
        - Set folder path where parquet files shall be uploaded to
        - 







### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices

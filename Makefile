AWSPROFILE="hbc-integration"
AWSREGION="us-east-1"
AWSROLEARN="arn:aws:iam::280550751197:role/HbcdLambdaFullAccess"
PYTHON_SITE_PACKAGES_FULL_PATH ?= "/PycharmProjects/myproj/venv/lib/python3.6/site-packages/"
LAMBDA_FUNCTION_NAME ?= "load_o5_inv_files_to_ddw"


install-inv-in-aws: package-local-libs
	@echo "zipping up the deployment package"
	@zip -g deployment.zip ./*py
	@echo "Initial install of lambda function"
	@aws --profile $(AWSPROFILE) lambda create-function --region $(AWSREGION) --function-name $(LAMBDA_FUNCTION_NAME) --runtime python3.6 --role $(AWSROLEARN) --handler load_inv_s3.lambda_handler --zip-file fileb://./deployment.zip

update-inv-in-aws: package-local-libs
	@echo "zipping up the deployment package"
	@zip -g deployment.zip ./load_inv_s3.py
	@echo "Updating the existing version"
	@aws --profile $(AWSPROFILE) lambda update-function-code --region $(AWSREGION) --function-name $(LAMBDA_FUNCTION_NAME) --zip-file fileb://./deployment.zip

install-inv-store-in-aws: package-local-libs
	@echo "zipping up the deployment package"
	@zip -g deployment.zip ./load_inv_store_s3.py
	@echo "Initial install of lambda function"
	@aws --profile $(AWSPROFILE) lambda create-function --region $(AWSREGION) --function-name $(LAMBDA_FUNCTION_NAME) --runtime python3.6 --role $(AWSROLEARN) --handler load_store_inv_s3.lambda_handler --zip-file fileb://./deployment.zip

update-inv-store-in-aws: package-local-libs
	@echo "zipping up the deployment package"
	@zip -g deployment.zip ./load_inv_store_s3.py
	@echo "Updating the existing version"
	@aws --profile $(AWSPROFILE) lambda update-function-code --region $(AWSREGION) --function-name $(LAMBDA_FUNCTION_NAME) --zip-file fileb://./deployment.zip

clean:
	@echo "Cleaning"
	@rm -f ./*zip

package-local-libs: clean
	@echo "Packaging up local libraries not available in AWS"
	@cd ${PYTHON_SITE_PACKAGES_FULL_PATH}; \
		zip -r9  deployment.zip ./cx_Oracle.cpython-36m-x86_64-linux-gnu.so ./cx_Oracle-7.3.0.dist-info/ ./lib64/; \
		mv ./deployment.zip $(PWD)
install-python-libs:
	@pip3 install -r requirements.txt

.PHONY: clean 

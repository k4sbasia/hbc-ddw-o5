import json
import cx_Oracle
import boto3
import base64


# path="/Users/isingh/Downloads/bay.inventory.v1*.json"


def get_folders(client):
    """Retrieve all folders within a specified directory.

    1. Set bucket name.
    2. Set delimiter (a character that our target files have in common).
    3. Set folder path to objects using "Prefix" attribute.
    4. Create list of all recursively discovered folder names.
    5. Return list of folders.
    """
    get_folder_objects = client.list_objects_v2(
        Bucket='ddw-inv-sink-poc',
        Delimiter='',
        EncodingType='url',
        MaxKeys=1000,
        Prefix='topics/o5a.inventory.v1/',
        FetchOwner=False,
        StartAfter=''
    )
    # print(get_folder_objects)
    folders = [item['Key'] for item in get_folder_objects['Contents']]
    return folders


def main():
    session = boto3.session.Session()
    s3_resource = session.resource('s3')

    client = session.client('s3')
    # everything=get_everything_ever()
    folders = get_folders(client)
    # # objects=get_objects_in_folder('topics')
    #
    print(folders)
    # # print(objects)
    #
    print("building connection")
    con = cx_Oracle.connect('o5/qsdw_2015@hd1mrc15nx.digital.hbc.com/QASDW')
    cur = con.cursor()
    print(con)
    cur.execute("select o5.INV_BATCH_SEQ.NEXTVAL from dual")
    batch_id, = cur.fetchone()
    print(batch_id)

    for file in folders:
        #     # print(file)
        file = file.replace('%2B', '+')
        file = file.replace('%3D', '=')
        print(file)
        cur = con.cursor()
        file_prcsd = ''
        cur.execute("select PRRCSD from O5.FILE_PROCESS_STATUS WHERE PROCESS_NAME=:1 and FILE_NAME=:2",
                    ('INV_LOAD', file))
        file_prcsd_tupl = cur.fetchone()
        if file_prcsd_tupl is None:
            file_prcsd = ''
        else:
            file_prcsd, = file_prcsd_tupl
        print(file_prcsd)
        if file_prcsd == 'C':
            print(file + ' already processed')
            continue
        elif file_prcsd == 'N' or file_prcsd == 'P' or file_prcsd == 'F':
            raise NameError('File received already processed ' + file)
            # continue
        else:
            cur = con.cursor()
            cur.execute("insert into O5.FILE_PROCESS_STATUS"
                        "(PROCESS_NAME ,FILE_NAME ) "
                        "values (:1, :2 )", ('INV_LOAD', file))
            con.commit()
            content_object = s3_resource.Object('ddw-inv-sink-poc', file)
            # print(content_object.get()['Body'])
            file_content = content_object.get()['Body'].read().decode('utf-8')
            file_content = file_content.splitlines()
            # print(file_content)
            data = [json.loads(line) for line in file_content]

            # for filename in glob.glob(path):
            #     with open(filename) as file:
            #         print(file)
            #         data = [json.loads(line) for line in file]

            # print(data)
            # print(type(data))

            rec_list = []
            for rec in data:
                data_list = []
                # print(rec)
                # print(type(rec))
                # print("Skn is "+ str(rec['SKN_NO']) + " PROMO_RETAIL_DOL is  "+ str(rec['PROMO_RETAIL_DOL']))
                # print("Item is {} , dummy is {}".format(rec['itemId'], rec['preorderBackorderHandling']['NotAny']['dummy']))
                message = base64.standard_b64decode(rec['allocation'])
                onhand = int(int.from_bytes(message, byteorder='big') / 100)
                # print (onhand)
                data_list = [rec['itemId'], rec['allocation'], onhand, rec['allocationTimestamp'],
                             rec['preorderBackorderHandling']['Backorder'],
                             rec['preorderBackorderHandling']['NotAny']['dummy'],
                             rec['preorderBackorderHandling']['Preorder'], rec['inStockDate'], rec['perpetual'],
                             batch_id]
                rec_list.append(data_list)

            cur.bindarraysize = 10000
            cur.executemany("insert into INVENTORY_V1"
                            "(itemId, allocation,ONHAND,allocationTimestamp,Backorder,dummy,Preorder,inStockDate,perpetual,batch_id) "
                            "values (:1, :2, :3, :4, :5, :6, :7, :8, :9 ,:10 )", rec_list)
            con.commit()
            cur.execute("UPDATE O5.FILE_PROCESS_STATUS SET PRRCSD='C' WHERE PROCESS_NAME=:1 and FILE_NAME=:2 ",
                        ('INV_LOAD', file))
            con.commit()
            # print("archive/" + file)
            # s3_resource.Object("ddw-inv-sink-poc", "archive/" + file).copy_from(CopySource="ddw-inv-sink-poc/" + file)
            # s3_resource.Object("ddw-inv-sink-poc", file).delete()


def lambda_handler(event, context):
    main()

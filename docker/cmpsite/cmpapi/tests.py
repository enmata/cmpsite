# cmpapi/tests.py
from django.test import TestCase
import requests
import os

class TestAPI(TestCase):

    # DJANGO_BASE_URL is set on configMap
    BASE_URL = os.environ['DJANGO_BASE_URL']

    def test_01_ready(self):
        #Emulating
        #curl -X GET $BASE_URL/user/
        #curl --insecure -X GET $BASE_URL_TLS/user/
        expected_payload = []
        req = requests.get(TestAPI.BASE_URL + '/user/')
        self.assertTrue(req.ok)
        self.assertEqual(req.status_code, 200)

    def test_02_insert(self):
        #Emulating
        #curl -X POST -H "Accept: Application/json" -H "Content-Type: application/json" -d '{"name":"ThisIsMyNameJSON"}' $BASE_URL/user/
        # curl --insecure -X POST -H "Accept: Application/json" -H "Content-Type: application/json" -d '{"name":"ThisIsMyNameJSON"}' $BASE_URL_TLS/user/
        input_payload = {"name":"ThisIsMyNameJSON"}
        expected_payload = {"id":1,"name":"ThisIsMyNameJSON"}
        req = requests.post(TestAPI.BASE_URL + '/user/', data=input_payload)
        self.assertTrue(req.ok)
        self.assertEqual(req.json(), expected_payload)

    def test_03_getonesuer(self):
        #Emulating
        #curl -X GET $BASE_URL/user/1/
        #curl --insecure -X GET $BASE_URL_TLS/secure/user/
        expected_payload = {"id":1,"name":"ThisIsMyNameJSON"}
        req = requests.get(TestAPI.BASE_URL + '/user/1/')
        self.assertTrue(req.ok)
        self.assertEqual(req.json(), expected_payload)

    def test_04_delete_exist(self):
        #Emulating
        #curl -X DELETE $BASE_URL/user/1/
        #curl --insecure -X GET $BASE_URL_TLS/secure/user/1/
        req = requests.delete(TestAPI.BASE_URL + '/user/1/')
        # self.assertTrue(req.ok)
        self.assertEqual(req.status_code, 204)

    def test_05_delete_doesntexist(self):
        #Emulating
        #curl -X DELETE $BASE_URL/user/3/
        #curl --insecure -X GET $BASE_URL_TLS/user/3/
        expected_payload = {"detail":"Not found."}
        req = requests.delete(TestAPI.BASE_URL + '/user/999/')
        self.assertFalse(req.ok)
        self.assertEqual(req.status_code, 404)
        self.assertEqual(req.json(), expected_payload)

    def test_06_method_no_exist(self):
        #Emulating
        #curl -X GET $BASE_URL/fakemethod/
        #curl --insecure -X GET $BASE_URL_TLS/fakemethod/
        req = requests.get(TestAPI.BASE_URL + '/fakemethod/')
        self.assertFalse(req.ok)
        self.assertEqual(req.status_code, 404)

    def test_07_heathcheck(self):
        #Emulating
        #curl -X GET $BASE_URL/hc/?format=json
        #curl --insecure -X GET $BASE_URL_TLS/hc/?format=json
        expected_payload = {"Cache backend: default": "working", "DatabaseBackend": "working", "DefaultFileStorageHealthCheck": "working", "MigrationsHealthCheck": "working"}
        req = requests.get(TestAPI.BASE_URL + '/hc/?format=json')
        self.assertTrue(req.ok)
        self.assertEqual(req.json(), expected_payload)

if __name__ == '__main__':
    #Setting additional verbosity
    unittest.main(verbosity=2)

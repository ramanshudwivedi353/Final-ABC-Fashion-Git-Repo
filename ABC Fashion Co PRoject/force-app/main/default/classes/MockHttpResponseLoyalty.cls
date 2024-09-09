public class MockHttpResponseLoyalty implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status": "success", "customer_id": "123456"}');
        res.setStatusCode(200);
        return res;
    }
}
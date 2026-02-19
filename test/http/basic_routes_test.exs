defmodule Echo.Http.BasicRoutesTest do
  use Echo.ConnCase, async: true

  describe "GET /api/health" do
    test "returns ok status" do
      conn = request("GET", "/api/health")
      response = json_response(conn, 200)
      assert response["status"] == "ok"
    end
  end

  describe "GET /api/docs" do
    test "returns HTTP docs as HTML" do
      conn = request("GET", "/api/docs")
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> List.first() =~ "text/html"
      assert conn.resp_body =~ "markdown-body"
    end
  end

  describe "GET /api/docs/ws" do
    test "returns WebSocket docs as HTML" do
      conn = request("GET", "/api/docs/ws")
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> List.first() =~ "text/html"
      assert conn.resp_body =~ "markdown-body"
    end
  end

  describe "404 handling" do
    test "returns 404 for unknown routes" do
      conn = request("GET", "/api/nonexistent")
      response = json_response(conn, 404)
      assert response["error"] == "Not found"
    end

    test "returns 404 for wrong method" do
      conn = request("PUT", "/api/health")
      response = json_response(conn, 404)
      assert response["error"] == "Not found"
    end
  end
end

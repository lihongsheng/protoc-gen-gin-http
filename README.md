# protoc-gen-gin-http
protoc-gen-gin-http 是基于proto google api来生成gin router代理的插件。实现的效果是当定义一个proto路由的时候。依托与[kratos-gen-http](https://github.com/go-kratos/kratos/tree/main/cmd/protoc-gen-go-http)
## 1. 我们先定义一个proto
```protobuf
service Demo {
  rpc Ping(Request) returns(Response) {
    option (google.api.http) = {
      post: "/api/grpcDemo/ping"
      body: "*"
    };
  };
}
```
## 2. 执行protoc 生成
```shell
protoc demo.proto --go_out=. --go-grpc_out=. --gin-http_out=.  -I .\third_party\ -I .\
```
在执行protoc 命令生成代码的时候指定使用protoc-gen-gin-http可以生成demo_gin_http.pb.go文件。需要主动调用RegisterDemoHTTPServer以便把路由注册到gin里。
```go

type DemoGinHTTPServerProxy struct {
	cc DemoClient
}

// NewDemoGinProxy
// 使用原生的 grpc.ClientConnInterface 可以使用原生的 grpc
func NewDemoGinProxy(cc grpc.ClientConnInterface) *DemoGinHTTPServerProxy {
	return &DemoGinHTTPServerProxy{cc: NewDemoClient(cc)}
}

// NewDemoGinClientProxy
// 传入 Client 可以使用zrpc 的Client
func NewDemoGinClientProxy(cc DemoClient) *DemoGinHTTPServerProxy {
	return &DemoGinHTTPServerProxy{cc: cc}
}

func DemoGinResponse(ctx *gin.Context, status, code int, msg string, data interface{}) {
	ctx.JSON(status, map[string]interface{}{
		"code": code,
		"msg":  msg,
		"data": data,
	})
}
func (s *DemoGinHTTPServerProxy) Ping0_HTTP_Handler(ctx *gin.Context) {
	var in Request

	if err := ctx.ShouldBindJSON(&in); err != nil {
		DemoGinResponse(ctx, 200, 400, err.Error(), nil)
		return
	}

	md := metadata.New(nil)
	for k, v := range ctx.Request.Header {
		md.Set(k, v...)
	}
	newCtx := metadata.NewIncomingContext(ctx, md)
	out, err := s.cc.Ping(newCtx, &in)
	if err != nil {
		DemoGinResponse(ctx, 200, 500, err.Error(), nil)
		return
	}

	DemoGinResponse(ctx, 200, 200, "success", out)
}

func (s *DemoGinHTTPServerProxy) RegisterDemoHTTPServer(group *gin.RouterGroup) {
	group.POST("/api/grpcDemo/ping", s.Ping0_HTTP_Handler)
}
```
## 3. 针对 gin 路由uri 参数
需要安装 go install github.com/favadi/protoc-go-inject-tag@latest 在proto 定义添加 tag
```protobuf
// 使用 // @gotags: form:"author_id" uri:"author_id" 定义路由参数
message GetArticlesReq {
  string title = 1;
  int32 page = 2;
  int32 page_size = 3;
  // 作者ID
  // @gotags: form:"author_id" uri:"author_id"
  int32 author_id = 4;
}
```
在执行过protoc 生成好grpc.pb.go文件之后 ，再次执行替换 proto生成的pb 定义文件，添加 gin tag,便于gin ShouldBingUri绑定uri 参数。
```shell
protoc-go-inject-tag -input demo.pb.go
```
最终会追加tag
```go
// 执行前
type GetArticlesReq struct {
	state    protoimpl.MessageState `protogen:"open.v1"`
	Title    string                 `protobuf:"bytes,1,opt,name=title,proto3" json:"title,omitempty"`
	Page     int32                  `protobuf:"varint,2,opt,name=page,proto3" json:"page,omitempty"`
	PageSize int32                  `protobuf:"varint,3,opt,name=page_size,json=pageSize,proto3" json:"page_size,omitempty"`
	// 作者ID
	// @gotags: form:"author_id" uri:"author_id"
	AuthorId      int32 `protobuf:"varint,4,opt,name=author_id,json=authorId,proto3" json:"author_id,omitempty"`
	unknownFields protoimpl.UnknownFields
	sizeCache     protoimpl.SizeCache
}
// 执行后
type GetArticlesReq struct {
	state    protoimpl.MessageState `protogen:"open.v1"`
	Title    string                 `protobuf:"bytes,1,opt,name=title,proto3" json:"title,omitempty"`
	Page     int32                  `protobuf:"varint,2,opt,name=page,proto3" json:"page,omitempty"`
	PageSize int32                  `protobuf:"varint,3,opt,name=page_size,json=pageSize,proto3" json:"page_size,omitempty"`
	// 作者ID
	// @gotags: form:"author_id" uri:"author_id"
	AuthorId      int32 `protobuf:"varint,4,opt,name=author_id,json=authorId,proto3" json:"author_id,omitempty" form:"author_id" uri:"author_id"`
	unknownFields protoimpl.UnknownFields
	sizeCache     protoimpl.SizeCache
}
```
## 3. 完整运行示例
```shell
# 先安装 go install github.com/lihongsheng/protoc-gen-gin-http@latest
protoc .\test\demo.proto --go_out=./test --go-grpc_out=./test --gin-http_out=./test -I .\third_party\ -I .\
# 给pb.go 加上gin tag,便于绑定uri 参数
protoc-go-inject-tag -input="$($PWD)\test\demo\demo.pb.go"
```

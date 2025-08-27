{{$svrType := .ServiceType}}
{{$svrName := .ServiceName}}


type {{.ServiceType}}GinHTTPServerProxy struct {
  cc {{.ServiceType}}Client
}
// New{{.ServiceType}}GinProxy
// 使用原生的 grpc.ClientConnInterface 可以使用原生的 grpc
func New{{.ServiceType}}GinProxy(cc grpc.ClientConnInterface) *{{.ServiceType}}GinHTTPServerProxy {
	return &{{.ServiceType}}GinHTTPServerProxy{cc:New{{.ServiceType}}Client(cc)}
}

// New{{.ServiceType}}GinClientProxy
// 传入 Client 可以使用zrpc 的Client
func New{{.ServiceType}}GinClientProxy(cc {{.ServiceType}}Client) *{{.ServiceType}}GinHTTPServerProxy {
	return &{{.ServiceType}}GinHTTPServerProxy{cc:cc}
}

func {{.ServiceType}}GinResponse(ctx *gin.Context, status, code int, msg string, data interface{}) {
	ctx.JSON(status, map[string]interface{}{
		"code": code,
		"msg": msg,
		"data": data,
	})
}

{{- range .Methods}}
func (s *{{$.ServiceType}}GinHTTPServerProxy) {{.Name}}{{.Num}}_HTTP_Handler(ctx *gin.Context) {
    var in {{.Request}}
    {{if .HasVars }}
    	if err := ctx.ShouldBindUri(&in); err != nil {
    		{{$.ServiceType}}GinResponse(ctx, 200, 400, err.Error(), nil)
    		return
    	}
    {{end}}
    {{if eq .Method "GET" "DELETE" }}
    	if err := ctx.ShouldBindQuery(&in); err != nil {
    		{{$.ServiceType}}GinResponse(ctx, 200, 400, err.Error(), nil)
    		return
    	}
    {{else if eq .Method "POST" "PUT" }}
    	if err := ctx.ShouldBindJSON(&in); err != nil {
    		{{$.ServiceType}}GinResponse(ctx, 200, 400, err.Error(), nil)
    		return
    	}
    {{else}}
    	if err := ctx.ShouldBind(&in); err != nil {
    		{{$.ServiceType}}GinResponse(ctx, 200, 400, err.Error(), nil)
    		return
    	}
    {{end}}
    	md := metadata.New(nil)
    	for k, v := range ctx.Request.Header {
    		md.Set(k, v...)
    	}
    	newCtx := metadata.NewIncomingContext(ctx, md)
        	out, err := s.cc.{{.Name}}(newCtx, &in)
        	if err != nil {
        		{{$.ServiceType}}GinResponse(ctx, 200, 500, err.Error(), nil)
        		return
        	}

        	{{$.ServiceType}}GinResponse(ctx, 200, 200, "success", out)
}
{{- end}}


func (s *{{.ServiceType}}GinHTTPServerProxy) Register{{.ServiceType}}HTTPServer(group *gin.RouterGroup) {
	{{- range .Methods}}
	group.{{.Method}}("{{.Path}}", s.{{.Name}}{{.Num}}_HTTP_Handler)
	{{- end}}
}

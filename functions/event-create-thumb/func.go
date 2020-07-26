package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"io"
	"io/ioutil"
	"log"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/disintegration/imaging"
	fdk "github.com/fnproject/fdk-go"
	"github.com/oracle/oci-go-sdk/common/auth"
	"github.com/oracle/oci-go-sdk/objectstorage"
)

var imgBucket string

// EventsInput structure will match the OCI events format
type EventsInput struct {
	CloudEventsVersion string      `json:"cloudEventsVersion"`
	EventID            string      `json:"eventID"`
	EventType          string      `json:"eventType"`
	Source             string      `json:"source"`
	EventTypeVersion   string      `json:"eventTypeVersion"`
	EventTime          time.Time   `json:"eventTime"`
	SchemaURL          interface{} `json:"schemaURL"`
	ContentType        string      `json:"contentType"`
	Extensions         struct {
		CompartmentID string `json:"compartmentId"`
	} `json:"extensions"`
	Data struct {
		CompartmentID      string `json:"compartmentId"`
		CompartmentName    string `json:"compartmentName"`
		ResourceName       string `json:"resourceName"`
		ResourceID         string `json:"resourceId"`
		AvailabilityDomain string `json:"availabilityDomain"`
		FreeFormTags       struct {
			Department string `json:"Department"`
		} `json:"freeFormTags"`
		DefinedTags struct {
			Operations struct {
				CostCenter string `json:"CostCenter"`
			} `json:"Operations"`
		} `json:"definedTags"`
		AdditionalDetails struct {
			Namespace        string `json:"namespace"`
			PublicAccessType string `json:"publicAccessType"`
			ETag             string `json:"eTag"`
		} `json:"additionalDetails"`
	} `json:"data"`
}

var imgTypeMapped = map[string]imaging.Format{
	".jpg": imaging.JPEG,
	".png": imaging.PNG,
	".gif": imaging.GIF,
}

func main() {
	fdk.Handle(fdk.HandlerFunc(dispatchHandler))
}

func dispatchHandler(ctx context.Context, in io.Reader, out io.Writer) {

	input := &EventsInput{}
	json.NewDecoder(in).Decode(input)

	imgBucket = os.Getenv("OCI_BUCKET_NAME")

	imgRex := regexp.MustCompile(`(.jpg|.gif|.png)$`)
	imgType := imgRex.FindString(strings.ToLower(input.Data.ResourceID))

	if imgType == "" || strings.Contains(input.Data.ResourceName, "thumb/") {
		log.Println("Skip processing ", input.Data.ResourceName)
		return
	}

	switch input.EventType {
	case "com.oraclecloud.objectstorage.deleteobject":
		outMsg, err := handleDelete(ctx, input)
		if err != nil {
			log.Println(outMsg, err)
		}
	case "com.oraclecloud.objectstorage.createobject":
		outMsg, err := handleCreateUpdate(ctx, imgType, input)
		if err != nil {
			log.Println(outMsg, err)
		}
	case "com.oraclecloud.objectstorage.updateobject":
		outMsg, err := handleCreateUpdate(ctx, imgType, input)
		if err != nil {
			log.Println(outMsg, err)
		}
	default:
		log.Fatalln("received unhandled event ", input.EventType)
	}

}

func handleCreateUpdate(ctx context.Context, extension string, event *EventsInput) (outMsg string, err error) {

	provider, err := auth.ResourcePrincipalConfigurationProvider()
	if err != nil {
		log.Fatalln("Error: ", err)
	}

	osClient, err := objectstorage.NewObjectStorageClientWithConfigurationProvider(provider)
	if err != nil {
		log.Println("Error: ", err)
		return
	}

	nsRequest := objectstorage.GetNamespaceRequest{}
	nsResp, err := osClient.GetNamespace(ctx, nsRequest)
	if err != nil {
		log.Println("Error: ", err)
		return
	}

	getReq := objectstorage.GetObjectRequest{
		NamespaceName: nsResp.Value,
		BucketName:    &imgBucket,
		ObjectName:    &event.Data.ResourceName,
	}

	getResp, err := osClient.GetObject(ctx, getReq)
	if err != nil {
		log.Println("Error: ", err)
		return
	}

	orig, err := imaging.Decode(getResp.Content)
	if err != nil {
		log.Println("Error: ", err)
		return
	}

	var b bytes.Buffer
	imgWriter := bufio.NewWriter(&b)

	thumb := imaging.Resize(orig, 200, 0, imaging.Lanczos)

	if err = imaging.Encode(imgWriter, thumb, imgTypeMapped[extension]); err != nil {
		log.Println("Error: ", err)
		return
	}
	imgWriter.Flush()

	thumbName := "thumb/" + event.Data.ResourceName
	thumbsize := int64(len(b.Bytes()))

	request := objectstorage.PutObjectRequest{
		NamespaceName: nsResp.Value,
		BucketName:    &imgBucket,
		ObjectName:    &thumbName,
		ContentLength: &thumbsize,
		PutObjectBody: ioutil.NopCloser(&b),
		OpcMeta:       nil,
	}
	if _, err = osClient.PutObject(ctx, request); err != nil {
		log.Println(err)
		return
	}
	return
}

// cleans up thumbs for images that are deleted from the bucket
func handleDelete(ctx context.Context, event *EventsInput) (outMsg string, err error) {

	provider, err := auth.ResourcePrincipalConfigurationProvider()
	if err != nil {
		log.Fatalln("Error: ", err)
	}

	osClient, err := objectstorage.NewObjectStorageClientWithConfigurationProvider(provider)
	if err != nil {
		log.Println("Error: ", err)
		return
	}

	nsRequest := objectstorage.GetNamespaceRequest{}
	nsResp, err := osClient.GetNamespace(ctx, nsRequest)
	if err != nil {
		log.Println("Error: ", err)
		return
	}

	thumbName := "thumb/" + event.Data.ResourceName
	deleteRequest := objectstorage.DeleteObjectRequest{
		NamespaceName: nsResp.Value,
		BucketName:    &imgBucket,
		ObjectName:    &thumbName,
	}

	if _, err = osClient.DeleteObject(ctx, deleteRequest); err != nil {
		log.Println("Error: ", err)
	}

	return
}

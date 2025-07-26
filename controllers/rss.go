package controllers

import (
	"fmt"
	"lyanna/models"
	"lyanna/utils"
	"regexp"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/feeds"
)

//var Logger = models.Logger

func GetRss(c *gin.Context) {
	now := utils.GetCurrentTime()
	feed := &feeds.Feed{
		Title:       "My Blog",
		Link:        &feeds.Link{Href: "http://127.0.0.1:9080"},
		Description: "A modern, beautiful blog powered by GoLyanna",
		Author:      &feeds.Author{Name: "szbolent", Email: "szbolent@example.com"},
		Created:     now,
	}
	feed.Items = make([]*feeds.Item, 0)
	posts, err := models.ListPublishedPost("")
	if err != nil {
		msg := fmt.Sprintf("list published posts err:%v", err)
		Logger.Fatal(msg)
	}
	for _, post := range posts {
		item := &feeds.Item{
			Id:          fmt.Sprintf("%s/post/%d", "http://127.0.0.1:9080", post.ID),
			Title:       post.Title,
			Link:        &feeds.Link{Href: fmt.Sprintf("%s/post/%d", "http://127.0.0.1:9080", post.ID)},
			Description: post.Summary,
			Created:     now,
		}
		feed.Items = append(feed.Items, item)
	}
	rss, err := feed.ToRss()
	if err != nil {
		msg := fmt.Sprintf("feed to rss err:%v", err)
		Logger.Fatal(msg)
	}
	// 使用正则表达式替换managingEditor信息
	re := regexp.MustCompile(`<managingEditor>admin@example\.com \(GoLyanna\)</managingEditor>`)
	rss = re.ReplaceAllString(rss, "<managingEditor>szbolent@example.com (szbolent)</managingEditor>")
	c.Writer.WriteString(rss)

}

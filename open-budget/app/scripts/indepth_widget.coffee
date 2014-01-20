class IndepthWidget extends Backbone.View

        TOP_PART_SIZE = 200 #p
        TICKS = 10

        YEAR_LINE_HANG_LENGTH = 46 # px
        CHANGE_LINE_HANG_LENGTH = 18 # px

        initialize: ->
                @pageModel = window.pageModel
                @pageModel.on 'change:selection', => @render()

                @svg = d3.select(@el).append('svg')
                        .attr('width','100%')
                        .attr('height','100%')
                @svg.append('defs').html('<pattern id="backgroundPattern" patternUnits="userSpaceOnUse" width="4" height="4"><path d="M-1,1 l2,-2 M0,4 l4,-4 M3,5 l2,-2" stroke-width="1" /></pattern>')
        
                @chart = @svg.append('g').attr('class','chart')
                @bars = @svg.append('g').attr('class','bar')

        render: ->

                @maxWidth = $(@el).width()
                @maxHeight = $(@el).height()

                @setValueRange()

                @minTime = @pageModel.get('selection')[0]
                @maxTime = @pageModel.get('selection')[1]
                
                @baseTimeScale = d3.scale.linear()
                        .domain([@minTime, @maxTime])
                        .range([0, @maxWidth])
                @timeScale = (t) =>
                        year = new Date(t).getFullYear()
                        base = new Date(year,0).valueOf()                       
                        #console.log t, year, base
                        @baseTimeScale( base + (t - base) * 0.98 )
                @valueScale = d3.scale.linear()
                        .domain([@minValue, @maxValue])
                        .range([TOP_PART_SIZE, 0])

                @chart.selectAll('.background').data([1])
                        .enter()
                                .append('rect')
                                .attr("class", "background")
                                .style("fill", "url(#backgroundPattern)")
                                .style("stroke", null)

                @chart.selectAll('.background').data([1])
                        .attr("x", (d) => @timeScale( @minTime ) )
                        .attr("y", (d) => @valueScale( @maxValue ) )
                        .attr("width", (d) => @timeScale( @maxTime ) - @timeScale( @minTime ) )
                        .attr("height", (d) => @valueScale( @minValue ) - @valueScale( @maxValue ) )

                allLabelIndexes = _.map([0..9], (x) =>
                        index: x
                        major: (@minValue + x*@tickValue) % @labelValue < 1
                        )

                @chart.selectAll(".graduationLine")
                        .data(allLabelIndexes)
                        .enter()
                                .append('line')
                                .attr('class', (d) -> 'graduationLine ' + (if d.major then "major" else "minor"))
                @chart.selectAll(".graduationLine")
                        .data(allLabelIndexes)
                        .attr('x1', (d) => @timeScale( @minTime ))
                        .attr('x2', (d) => @timeScale( @maxTime ))
                        .attr('y1', (d) => @valueScale( @minValue + d.index*@tickValue ))
                        .attr('y2', (d) => @valueScale( @minValue + d.index*@tickValue ))
                
                graduationLabels = @chart.selectAll('.graduationLabel')
                        .data(_.filter(allLabelIndexes, (x)->x.major))
                graduationLabels.enter()
                        .append('text')
                        .attr("class", "graduationLabel")
                        .attr("x", (d) => @timeScale( @minTime ) )
                        .attr("y", (d) => @valueScale( @minValue + d.index*@tickValue ) )
                        .attr("dx", 5 )
                        .attr("dy", -1 )
                        .style("font-size", 8)
                        .style("text-anchor", "end")
                        .text((d) => @formatNumber( @minValue + d.index*@tickValue ) )

                approvedModels = _.filter(@model.models, (x)->x.get('kind')=='approved')
                newGraphParts = @chart.selectAll('.graphPartApproved').data(approvedModels)
                        .enter().append("g")
                        .attr('class','graphPartApproved')
                newGraphParts
                        .append('line')
                                .attr('class', 'yearlyHang')
                                .datum( (d) => d)
                newGraphParts
                        .append('text')
                                .attr('class', 'approvedLabel')
                                .style("font-size", 10)
                                .attr("dx",3)
                                .text((d) => d.get('date').getFullYear())
                                .style("text-anchor", "end")
                                .datum( (d) => d)

                @chart.selectAll('.yearlyHang').data(approvedModels)
                        .attr("x1", (d) => @timeScale( d.get('timestamp') ) )
                        .attr("x2", (d) => @timeScale( d.get('timestamp') ) )
                        .attr("y1", (d) => @valueScale( d.get('value') ) )
                        .attr("y2", (d) => @valueScale( @minValue ) + YEAR_LINE_HANG_LENGTH )
                @chart.selectAll('.approvedLabel').data(approvedModels)
                        .attr("x", (d) => @timeScale( d.get('timestamp') ) )
                        .attr("y", (d) => @valueScale( @minValue ) + YEAR_LINE_HANG_LENGTH )

                changeModels = _.filter(@model.models, (x)->x.get('kind')=='change')
                newGraphParts = @chart.selectAll('.graphPartChanged').data(changeModels)
                        .enter().append("g")
                        .attr('class','graphPartChanged')
                newGraphParts
                        .append('line')
                                .attr('class', 'changeBar')
                                .datum( (d) => d)
                newGraphParts
                        .append('line')
                                .attr('class', 'changeLine')
                                .datum( (d) => d)

                @chart.selectAll('.changeBar').data(changeModels)
                        .attr("x1", (d) => @timeScale( d.get('timestamp') ) )
                        .attr("x2", (d) => @timeScale( d.get('timestamp') + d.get('width') ) )
                        .attr("y1", (d) => @valueScale( d.get('value') ) )
                        .attr("y2", (d) => @valueScale( d.get('value') )  )
                @chart.selectAll('.changeLine').data(changeModels)
                        .attr("x1", (d) => @timeScale( d.get('timestamp') ) )
                        .attr("x2", (d) => @timeScale( d.get('timestamp') ) )
                        .attr("y1", (d) => @valueScale( d.get('value') - d.get('diff-value') ) )
                        .attr("y2", (d) => @valueScale( @minValue ) + CHANGE_LINE_HANG_LENGTH  )

                        
                
        formatNumber: (n) ->
                rx=  /(\d+)(\d{3})/
                String(n*1000).replace(/^\d+/, (w) -> 
                        while rx.test(w)
                            w = w.replace rx, '$1,$2'
                        w)
                
        setValueRange: () ->
                @valueRange = @model.maxValue - @model.minValue
                scale = 1
                valueRange = @valueRange
                RATIO = (TICKS-1) / TICKS
                while valueRange > 1*RATIO
                        scale *= 10
                        valueRange /= 10
                if valueRange < 0.25*RATIO
                        @tickValue = 0.025*scale
                        @labelValue = 0.1*scale 
                if valueRange < 0.5*RATIO
                        @tickValue = 0.05*scale
                        @labelValue = 0.2*scale 
                if valueRange <=1*RATIO
                        @tickValue = 0.1*scale
                        @labelValue = 0.2*scale
                @minValue = Math.floor(@model.minValue / @tickValue) * @tickValue
                @maxValue = @minValue + TICKS * @tickValue
                        
                
        
$( ->
        console.log "indepth_widget"
        window.indepthWidget = new IndepthWidget({el: $("#indepth-widget"),model: window.widgetData});
)
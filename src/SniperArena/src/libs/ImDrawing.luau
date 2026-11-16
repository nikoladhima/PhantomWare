local BoxPool, LinePool, TextPool = table.create(128), table.create(428), table.create(128)
local CirclePool, TrianglePool = table.create(256), table.create(32)

local UsedBoxCount, ActiveBoxCount = 0, 0
local UsedLineCount, ActiveLineCount = 0, 0
local UsedTextCount, ActiveTextCount = 0, 0
local UsedCircleCount, ActiveCircleCount = 0, 0
local UsedTriangleCount, ActiveTriangleCount = 0, 0

return {
    NewFrame = function()
        UsedBoxCount, UsedLineCount, UsedTextCount, UsedTriangleCount, UsedCircleCount = 0, 0, 0, 0, 0
    end,

    Box = function(Filled, Position, Size, Color, Thickness, Transparency, ZIndex)
        local Index = UsedBoxCount + 1
        UsedBoxCount = Index

        local DrawingObject = BoxPool[Index]
        if not DrawingObject then
            DrawingObject = Drawing.new("Square")
            BoxPool[Index] = DrawingObject
        end

        DrawingObject.Filled = Filled
        DrawingObject.ZIndex = ZIndex or 1
        DrawingObject.Position = Position
        DrawingObject.Size = Size
        DrawingObject.Color = Color
        DrawingObject.Thickness = Thickness
        DrawingObject.Transparency = Transparency
        DrawingObject.Visible = true
    end,

    Line = function(From, To, Color, Thickness, Transparency)
        local Index = UsedLineCount + 1
        UsedLineCount = Index

        local DrawingObject = LinePool[Index]
        if not DrawingObject then
            DrawingObject = Drawing.new("Line")
            LinePool[Index] = DrawingObject
        end

        DrawingObject.From = From
        DrawingObject.To = To
        DrawingObject.Color = Color
        DrawingObject.Thickness = Thickness
        DrawingObject.Transparency = Transparency
        DrawingObject.Visible = true
    end,

    Text = function(Position, Content, Color, TextSize, Transparency, ZIndex)
        local Index = UsedTextCount + 1
        UsedTextCount = Index

        local DrawingObject = TextPool[Index]
        if not DrawingObject then
            DrawingObject = Drawing.new("Text")
            DrawingObject.Center = true
            DrawingObject.Outline = true
            TextPool[Index] = DrawingObject
        end

        DrawingObject.Position = Position
        DrawingObject.Text = Content
        DrawingObject.ZIndex = ZIndex or 1
        DrawingObject.Color = Color
        DrawingObject.Size = TextSize
        DrawingObject.Transparency = Transparency
        DrawingObject.Visible = true
    end,

    Circle = function(Filled, Position, Radius, Color, Thickness, Transparency)
        local Index = UsedCircleCount + 1
        UsedCircleCount = Index

        local DrawingObject = CirclePool[Index]
        if not DrawingObject then
            DrawingObject = Drawing.new("Circle")
            CirclePool[Index] = DrawingObject
        end

        DrawingObject.Filled = Filled
        DrawingObject.Position = Position
        DrawingObject.Radius = Radius
        DrawingObject.Color = Color
        DrawingObject.Thickness = Thickness
        DrawingObject.Transparency = Transparency
        DrawingObject.Visible = true
    end,

    Triangle = function(Filled, PointA, PointB, PointC, Color, Thickness, Transparency)
        local Index = UsedTriangleCount + 1
        UsedTriangleCount = Index

        local DrawingObject = TrianglePool[Index]
        if not DrawingObject then
            DrawingObject = Drawing.new("Triangle")
            TrianglePool[Index] = DrawingObject
        end

        DrawingObject.Filled = Filled
        DrawingObject.PointA = PointA
        DrawingObject.PointB = PointB
        DrawingObject.PointC = PointC
        DrawingObject.Color = Color
        DrawingObject.Thickness = Thickness
        DrawingObject.Transparency = Transparency
        DrawingObject.Visible = true
    end,

    EndFrame = function()
        for Index = UsedBoxCount + 1, ActiveBoxCount do
            BoxPool[Index].Visible = false
        end
        ActiveBoxCount = UsedBoxCount

        for Index = UsedLineCount + 1, ActiveLineCount do
            LinePool[Index].Visible = false
        end
        ActiveLineCount = UsedLineCount

        for Index = UsedTextCount + 1, ActiveTextCount do
            TextPool[Index].Visible = false
        end
        ActiveTextCount = UsedTextCount

        for Index = UsedCircleCount + 1, ActiveCircleCount do
            CirclePool[Index].Visible = false
        end
        ActiveCircleCount = UsedCircleCount

        for Index = UsedTriangleCount + 1, ActiveTriangleCount do
            TrianglePool[Index].Visible = false
        end
        ActiveTriangleCount = UsedTriangleCount
    end
}

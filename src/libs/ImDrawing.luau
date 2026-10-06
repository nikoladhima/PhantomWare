local ImDrawing = {}

local BoxPool = table.create(64)
local LinePool = table.create(32)
local TextPool = table.create(32)
local CirclePool = table.create(64)
local TrianglePool = table.create(16)

local UsedBoxCount = 0
local ActiveBoxCount = 0

local UsedLineCount = 0
local ActiveLineCount = 0

local UsedTextCount = 0
local ActiveTextCount = 0

local UsedCircleCount = 0
local ActiveCircleCount = 0

local UsedTriangleCount = 0
local ActiveTriangleCount = 0

function ImDrawing.NewFrame()
    UsedBoxCount = 0
    UsedLineCount = 0
    UsedTextCount = 0
    UsedCircleCount = 0
    UsedTriangleCount = 0
end

function ImDrawing.Box(Filled, Position, Size, Color, Thickness, Transparency)
    local Index = UsedBoxCount + 1
    UsedBoxCount = Index

    local DrawingObject = BoxPool[Index]
    if not DrawingObject then
        DrawingObject = Drawing.new("Square")
        BoxPool[Index] = DrawingObject
    end

    DrawingObject.Filled = Filled
    DrawingObject.Position = Position
    DrawingObject.Size = Size
    DrawingObject.Color = Color
    DrawingObject.Thickness = Thickness
    DrawingObject.Transparency = Transparency
    DrawingObject.Visible = true
end

function ImDrawing.Line(From, To, Color, Thickness, Transparency)
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
end

function ImDrawing.Text(Position, Content, Color, TextSize, Transparency)
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
    DrawingObject.Color = Color
    DrawingObject.Size = TextSize
    DrawingObject.Transparency = Transparency
    DrawingObject.Visible = true
end

function ImDrawing.Circle(Filled, Position, Radius, Color, Thickness, Transparency)
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
end

function ImDrawing.Triangle(Filled, PointA, PointB, PointC, Color, Thickness, Transparency)
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
end

function ImDrawing.EndFrame()
    if UsedBoxCount < ActiveBoxCount then
        for Index = UsedBoxCount + 1, ActiveBoxCount do
            BoxPool[Index].Visible = false
        end
    end
    ActiveBoxCount = UsedBoxCount

    if UsedLineCount < ActiveLineCount then
        for Index = UsedLineCount + 1, ActiveLineCount do
            LinePool[Index].Visible = false
        end
    end
    ActiveLineCount = UsedLineCount

    if UsedTextCount < ActiveTextCount then
        for Index = UsedTextCount + 1, ActiveTextCount do
            TextPool[Index].Visible = false
        end
    end
    ActiveTextCount = UsedTextCount

    if UsedCircleCount < ActiveCircleCount then
        for Index = UsedCircleCount + 1, ActiveCircleCount do
            CirclePool[Index].Visible = false
        end
    end
    ActiveCircleCount = UsedCircleCount

    if UsedTriangleCount < ActiveTriangleCount then
        for Index = UsedTriangleCount + 1, ActiveTriangleCount do
            TrianglePool[Index].Visible = false
        end
    end
    ActiveTriangleCount = UsedTriangleCount
end

return ImDrawing

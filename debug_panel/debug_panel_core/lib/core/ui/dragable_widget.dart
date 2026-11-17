import 'package:flutter/material.dart';

typedef DragCompletion<T> = void Function(List<T> data);

typedef DataWidgetBuilder<T> = Widget Function(BuildContext context, T data);

class DragableGridView<T> extends StatefulWidget {
  final DataWidgetBuilder<T> itemBuilder;
  final List<T> dataList;
  final int crossAxisCount;
  final double childAspectRatio;
  final DragCompletion<T>? dragCompletion;

  DragableGridView(
    this.dataList, {
    Key? key,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.dragCompletion,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  State<DragableGridView<T>> createState() => _DragableGridViewState<T>();
}

class _DragableGridViewState<T> extends State<DragableGridView<T>> {
  late List<T> dataList;
  late List<T> dataListBackup;
  bool showItemWhenCovered = false;
  int willAcceptIndex = -1;
  int draggingItemIndex = -1;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    dataList = List<T>.of(widget.dataList);
    dataListBackup = List<T>.of(dataList);
  }

  @override
  void didUpdateWidget(DragableGridView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.dataList, oldWidget.dataList)) _reset();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: dataList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemBuilder: ((ctx, index) {
        return _buildDraggable(ctx, index);
      }),
    );
  }

  Widget _buildDraggable(BuildContext context, int index) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return LongPressDraggable(
          data: index,
          child: DragTarget<int>(
            onAcceptWithDetails: (_) {},
            builder: (context, data, rejects) {
              return willAcceptIndex >= 0 && willAcceptIndex == index
                  ? Container()
                  : widget.itemBuilder(context, dataList[index]);
            },
            onLeave: (_) {
              willAcceptIndex = -1;
              setState(() {
                showItemWhenCovered = false;
                dataList = dataListBackup.sublist(0);
              });
            },
            onWillAcceptWithDetails: (details) {
              final fromIndex = details.data;
              final accept = fromIndex != index;
              if (accept) {
                willAcceptIndex = index;
                showItemWhenCovered = true;
                dataList = dataListBackup.sublist(0);
                final fromData = dataList[fromIndex];
                setState(() {
                  dataList.removeAt(fromIndex);
                  dataList.insert(index, fromData);
                });
              }
              return accept;
            },
          ),
          onDragStarted: () {
            draggingItemIndex = index;
            dataListBackup = dataList.sublist(0);
          },
          onDraggableCanceled: (Velocity velocity, Offset offset) {
            setState(() {
              willAcceptIndex = -1;
              showItemWhenCovered = false;
              dataList = dataListBackup.sublist(0);
            });
          },
          onDragCompleted: () {
            if (widget.dragCompletion != null) {
              widget.dragCompletion!(dataList);
            }
            setState(() {
              showItemWhenCovered = false;
              willAcceptIndex = -1;
            });
          },
          feedback: Material(
            color: Colors.white,
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: constraint.maxWidth,
              height: constraint.maxHeight,
              child: widget.itemBuilder(context, dataList[index]),
            ),
          ),
          childWhenDragging: Container(
            child: SizedBox(
              child: showItemWhenCovered
                  ? widget.itemBuilder(context, dataList[index])
                  : null,
            ),
          ),
        );
      },
    );
  }
}


CXX = g++
CXXFlAGS = -std=c++14 -O3 -I.

ODIR = obj

SRCS = main.cpp interlayer.cpp util.cpp component.cpp specification.cpp parse.cpp fc_layer.cpp dynamic.cpp fcbin_layer.cpp bias_op.cpp sigmoid_op.cpp conv2d_family_layer.cpp conv2d_layer.cpp pool_layer.cpp relu_op.cpp 

_OBJS = $(subst .cpp,.o,$(SRCS))
OBJS = $(patsubst %,$(ODIR)/%,$(_OBJS))

all: nngen

nngen: $(OBJS)
	$(CXX) -o $@ $(OBJS) $(CXXFLAGS)

$(ODIR)/main.o: main.cpp sim_interface.h sigmoid_op.h block_interface.h bias_op.h feed_interface.h interlayer.h gen.h fc_layer.h dynamic.h test_interface.h convtest_interface.h util.h component.h parse.h dummy.h interface.h specification.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/interlayer.o: interlayer.cpp conv2d_family_layer.h fc_layer.h dummy.h fc_to_fc_interlayer.h conv2d_layer.h dynamic.h bram_pad_interlayer.h interlayer.h fcbin_to_fc_interlayer.h fc_to_fcbin_interlayer.h fcbin_to_fcbin_interlayer.h conv_to_fc_interlayer.h component.h util.h parse.h fcbin_layer.h specification.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/util.o: util.cpp util.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/component.o: component.cpp component.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/specification.o: specification.cpp specification.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/parse.o: parse.cpp specification.h util.h dynamic.h parse.h component.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/fc_layer.o: fc_layer.cpp specification.h dynamic.h dummy.h fc_layer.h conv2d_family_layer.h interlayer.h parse.h util.h component.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/dynamic.o: dynamic.cpp component.h util.h dynamic.h specification.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/fcbin_layer.o: fcbin_layer.cpp interlayer.h fcbin_layer.h specification.h dynamic.h parse.h component.h util.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/bias_op.o: bias_op.cpp parse.h util.h dynamic.h component.h bias_op.h specification.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/sigmoid_op.o: sigmoid_op.cpp parse.h util.h dynamic.h component.h sigmoid_op.h specification.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/conv2d_family_layer.o: conv2d_family_layer.cpp interlayer.h specification.h conv2d_family_layer.h component.h parse.h util.h pool_layer.h dynamic.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/conv2d_layer.o: conv2d_layer.cpp interlayer.h specification.h conv2d_layer.h component.h parse.h util.h dynamic.h conv2d_family_layer.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/pool_layer.o: pool_layer.cpp interlayer.h specification.h conv2d_family_layer.h component.h parse.h util.h pool_layer.h dynamic.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)
$(ODIR)/relu_op.o: relu_op.cpp parse.h util.h dynamic.h component.h relu_op.h specification.h
	$(CXX) -c -o $@ $< $(CXXFlAGS)


.PHONY: clean

clean:
	rm -f $(ODIR)/*.o
